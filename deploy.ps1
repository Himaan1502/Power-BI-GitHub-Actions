param (
    [Parameter(Mandatory = $false)][string]$WorkspaceId,
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $true)][string]$ClientId,
    [Parameter(Mandatory = $false)][string]$ClientSecret
)

# -------------------------------
# Resolve WorkspaceId (auto or hardcoded mapping)
# -------------------------------
if ([string]::IsNullOrWhiteSpace($WorkspaceId)) {
    Write-Host "No WorkspaceId provided via pipeline input. Falling back to hardcoded mapping..."

    switch ($Environment.ToLower()) {
        "dev" {
            $WorkspaceId = "bc004410-9b58-4064-9967-8ad2c352fba3"
        }
        "uat" {
            $WorkspaceId = "8bba631c-8861-4937-bea9-3a61058ea89e"
        }
        "prod" {
            $WorkspaceId = "62bab185-e9a7-4926-b319-2bae50e1d848"
        }
        default {
            throw "Unknown environment: $Environment. Please provide a WorkspaceId."
        }
    }
}
else {
    Write-Host "Using WorkspaceId provided by pipeline input: $WorkspaceId"
}

# -------------------------------
# Authentication
# -------------------------------
Write-Host "🔑 Authenticating to Power BI..."
Write-Host "Environment: $Environment"
Write-Host "WorkspaceId: $WorkspaceId"

if ([string]::IsNullOrWhiteSpace($ClientSecret)) {
    Write-Host "Using OIDC authentication (no ClientSecret provided)..."
    Connect-PowerBIServiceAccount `
        -Tenant $TenantId `
        -ClientId $ClientId
}
else {
    Write-Host "Using Service Principal authentication (with ClientSecret)..."
    Connect-PowerBIServiceAccount -ServicePrincipal `
        -Tenant $TenantId `
        -ClientId $ClientId `
        -ClientSecret $ClientSecret
}

Write-Host "✅ Authenticated. Beginning deployment..."

# -------------------------------
# Deployment logic
# -------------------------------
$pbixPath = Join-Path $PSScriptRoot "reports"

if (-not (Test-Path $pbixPath)) {
    throw "PBIX path not found: $pbixPath"
}

$pbixFiles = Get-ChildItem -Path $pbixPath -Filter *.pbix

if ($pbixFiles.Count -eq 0) {
    throw "No PBIX files found in $pbixPath"
}

foreach ($pbix in $pbixFiles) {
    Write-Host "🚀 Deploying report: $($pbix.Name) to workspace $WorkspaceId"

    # Import the PBIX into workspace (overwrite if already exists)
    $import = New-PowerBIReport `
        -Path $pbix.FullName `
        -Name $pbix.BaseName `
        -WorkspaceId $WorkspaceId `
        -ConflictAction CreateOrOverwrite

    Write-Host "✅ Report deployed: $($import.Name)"

    # Refresh dataset if exists
    $dataset = Get-PowerBIDataset -WorkspaceId $WorkspaceId | Where-Object { $_.Name -eq $pbix.BaseName }

    if ($dataset) {
        Write-Host "🔄 Triggering refresh for dataset: $($dataset.Name)"
        Invoke-PowerBIDatasetRefresh -WorkspaceId $WorkspaceId -Id $dataset.Id -Wait
        Write-Host "✅ Dataset refreshed: $($dataset.Name)"
    }
    else {
        Write-Warning "⚠ No dataset found for report: $($pbix.BaseName)"
    }
}

Write-Host "🎉 Deployment completed for environment: $Environment"

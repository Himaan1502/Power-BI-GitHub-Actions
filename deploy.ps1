param (
    [Parameter(Mandatory = $true)][string]$WorkspaceId,
    [Parameter(Mandatory = $false)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $true)][string]$ClientId,
    [Parameter(Mandatory = $true)][string]$ClientSecret
)

Write-Host "🔑 Authenticating to Power BI..."
Write-Host "Environment: $Environment"
Write-Host "WorkspaceId: $WorkspaceId"

try {
    $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)

    Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $TenantId
    Write-Host "✅ Successfully authenticated to Power BI"
} catch {
    Write-Error "❌ Authentication failed: $($_.Exception.Message)"
    exit 1
}

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

    try {
        $import = New-PowerBIReport `
            -Path $pbix.FullName `
            -Name $pbix.BaseName `
            -WorkspaceId $WorkspaceId `
            -ConflictAction CreateOrOverwrite

        Write-Host "✅ Report deployed: $($import.Name)"
    } catch {
        Write-Warning "⚠ Failed to deploy report $($pbix.Name): $($_.Exception.Message)"
        continue
    }

    try {
        $dataset = Get-PowerBIDataset -WorkspaceId $WorkspaceId | Where-Object { $_.Name -eq $pbix.BaseName }
        if ($dataset) {
            Write-Host "🔄 Triggering refresh for dataset: $($dataset.Name)"
            Invoke-PowerBIDatasetRefresh -WorkspaceId $WorkspaceId -Id $dataset.Id -Wait
            Write-Host "✅ Dataset refreshed: $($dataset.Name)"
        } else {
            Write-Warning "⚠ No dataset found for report: $($pbix.BaseName)"
        }
    } catch {
        Write-Warning "⚠ Dataset refresh failed for report $($pbix.BaseName): $($_.Exception.Message)"
    }
}

Write-Host "🎉 Deployment completed for environment: $Environment"

param (
    [Parameter(Mandatory = $false)][string]$WorkspaceId,
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $true)][string]$ClientId,
    [Parameter(Mandatory = $true)][string]$ClientSecret
)

# -------------------------------
# Resolve WorkspaceId
# -------------------------------
if ([string]::IsNullOrWhiteSpace($WorkspaceId)) {
    Write-Host "⚠️ No WorkspaceId provided via pipeline input. Falling back to hardcoded values..."

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
            throw "❌ Unknown environment: $Environment. Please provide a valid WorkspaceId."
        }
    }
}
else {
    Write-Host "✅ Using WorkspaceId provided by pipeline input: $WorkspaceId"
}

# -------------------------------
# Authentication
# -------------------------------
Write-Host "🔑 Authenticating to Power BI..."
Connect-PowerBIServiceAccount -ServicePrincipal `
    -Tenant $TenantId `
    -ClientId $ClientId `
    -ClientSecret $ClientSecret

if (-not $?) {
    throw "❌ Failed to authenticate to Power BI Service."
}

# -------------------------------
# Deployment Logic
# -------------------------------
Write-Host "🚀 Starting deployment..."
Write-Host "   → Environment  : $Environment"
Write-Host "   → WorkspaceId  : $WorkspaceId"
Write-Host "   → TenantId     : $TenantId"
Write-Host "   → ClientId     : $ClientId"

# -------------------------------
# TODO: Replace with actual deployment steps
# Example: Import PBIX, update dataset, refresh, etc.
# -------------------------------
# Example placeholder:
# New-PowerBIReport -Path "./Reports/SalesReport.pbix" -Name "Sales Report" -WorkspaceId $WorkspaceId -ConflictAction CreateOrOverwrite

Write-Host "✅ Deployment completed successfully for environment: $Environment"

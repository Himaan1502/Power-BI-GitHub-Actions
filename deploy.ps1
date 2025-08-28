param (
    [Parameter(Mandatory = $true)][string]$WorkspaceId,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $true)][string]$ClientId,
    [Parameter(Mandatory = $false)][string]$ClientSecret
)

Write-Host "Authenticating to Power BI Service..."

if ([string]::IsNullOrWhiteSpace($ClientSecret)) {
    # ✅ OIDC-based login (token from `azure/login`)
    Connect-PowerBIServiceAccount -ServicePrincipal `
        -Tenant $TenantId `
        -ClientId $ClientId
}
else {
    # ✅ Fallback if ClientSecret is provided
    Connect-PowerBIServiceAccount -ServicePrincipal `
        -Tenant $TenantId `
        -ClientId $ClientId `
        -ClientSecret $ClientSecret
}

Write-Host "Deploying PBIX files to workspace $WorkspaceId..."

# Adjust folder as needed ("./reports" or ".")
$pbixFiles = Get-ChildItem -Path "./reports" -Filter *.pbix -Recurse

foreach ($file in $pbixFiles) {
    Write-Host "Uploading $($file.Name)..."

    Import-PowerBIReport `
        -Path $file.FullName `
        -WorkspaceId $WorkspaceId `
        -Name $file.BaseName `
        -ConflictAction CreateOrOverwrite
}

Write-Host "Deployment completed successfully."

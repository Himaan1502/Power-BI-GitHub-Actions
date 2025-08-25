param (
    [Parameter(Mandatory=$true)][string]$WorkspaceId,
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$ClientId,
    [Parameter(Mandatory=$true)][string]$ClientSecret
)

Write-Host "Authenticating to Power BI Service..."
Connect-PowerBIServiceAccount -ServicePrincipal `
    -Tenant $TenantId `
    -ClientId $ClientId `
    -ClientSecret $ClientSecret

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

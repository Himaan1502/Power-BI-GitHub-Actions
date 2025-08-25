param (
    [string]$WorkspaceId
)

Write-Host "🚀 Deploying reports to Workspace: $WorkspaceId"

# Connect to Power BI
Connect-PowerBIServiceAccount -ServicePrincipal `
    -Tenant $env:AZURE_TENANT_ID `
    -ClientId $env:AZURE_CLIENT_ID `
    -ClientSecret $env:AZURE_CLIENT_SECRET

# Path to PBIX files (change if needed)
$pbixFiles = Get-ChildItem -Path "./reports" -Filter *.pbix

foreach ($pbix in $pbixFiles) {
    Write-Host "📤 Publishing $($pbix.Name) to workspace $WorkspaceId"

    try {
        New-PowerBIReport `
            -Path $pbix.FullName `
            -Name $pbix.BaseName `
            -WorkspaceId $WorkspaceId `
            -ConflictAction CreateOrOverwrite `
            -ErrorAction Stop

        Write-Host "✅ Successfully deployed: $($pbix.Name)"
    }
    catch {
        Write-Host "❌ Failed deploying $($pbix.Name): $_"
        exit 1
    }
}

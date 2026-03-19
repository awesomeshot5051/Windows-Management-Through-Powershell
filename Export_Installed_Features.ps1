param (
    [string]$OutputPath
)

# Get current user's Desktop path
$userDesktop = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop", "AuditReports")

# If no custom output path is provided
if (-not $OutputPath) {
    # Create the folder if it doesn't exist
    if (-not (Test-Path -Path $userDesktop)) {
        New-Item -ItemType Directory -Path $userDesktop -Force | Out-Null
    }

    # Generate timestamped filename
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
    $fileName = "InstalledFeatures_$timestamp.csv"
    $OutputPath = Join-Path $userDesktop $fileName
}

# Get all installed roles and features
$features = Get-WindowsFeature | Where-Object { $_.Installed -eq $true }

# Display count
Write-Host "`nTotal Installed Roles and Features: $($features.Count)`n" -ForegroundColor Cyan

# Prepare for export
$exportData = $features | Select-Object Name, DisplayName, @{Name="Installed";Expression={ $_.Installed }}

# Export to CSV
$exportData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Export complete. File saved to:`n$OutputPath" -ForegroundColor Green

Export_Installed_Features.ps1
-----------------------------

This PowerShell script retrieves all **installed roles and features** from a Windows system and exports the information to a timestamped CSV file.

What it does:
- Lists all installed Windows Features and Roles
- Shows the total number of installed components
- Saves the list to a CSV file with:
  - Name
  - Display Name
  - Installed (always 'True')

Default Behavior:
- Saves to: Desktop\AuditReports on the current user’s account
- Automatically creates the folder if needed
- File name example: InstalledFeatures_2025-06-03_1430.csv

Custom Output Path:
- You can specify a custom file path like this:

  powershell.exe -ExecutionPolicy Bypass -File .\Export_Installed_Features.ps1 -OutputPath "D:\Reports\MyFeatures.csv"

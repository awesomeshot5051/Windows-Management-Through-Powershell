<#
Author: Trae England
Student Number: n01520193
Description: This script prompts the user to input employee names and their weekly hours,
calculates the total and average hours worked, and generates a report as an ASCII text file.
#>

# Initialize variables
$employees = @()
$totalHours = 0

# Collect employee data using a loop
do {
    $name = Read-Host "Enter employee name"
    
    # Validate and convert input to integer
    do {
        $hoursInput = Read-Host "Enter hours worked by $name"
        [int]$hours = 0
        $isValid = [int]::TryParse($hoursInput, [ref]$hours)
        if (-not $isValid -or $hours -lt 0) {
            Write-Host "Invalid input. Please enter a valid number of hours." -ForegroundColor Red
        }
    } while (-not $isValid -or $hours -lt 0)

    # Store employee data in a custom object
    $employee = [PSCustomObject]@{
        Name  = $name
        Hours = $hours
    }
    $employees += $employee
    $totalHours += $hours

    # Ask if the user wants to add another employee
    $continue = Read-Host "Do you want to enter another employee? (yes/no)"
} while ($continue -match '^(y|yes)$')

# Calculate average hours
$employeeCount = $employees.Count
if ($employeeCount -gt 0) {
    $averageHours = [math]::Round($totalHours / $employeeCount, 2)
} else {
    $averageHours = 0
}

# Prompt for output file path
$outputPath = Read-Host "Enter full path and filename for the output report (e.g., C:\Reports\EmployeeReport.txt)"

# Build the report content
$reportLines = @()
$reportLines += "Employee Hours Report"
$reportLines += "---------------------"

foreach ($emp in $employees) {
    $reportLines += "Name: $($emp.Name), Hours Worked: $($emp.Hours)"
}

$reportLines += ""
$reportLines += "Total Hours Worked: $totalHours"
$reportLines += "Average Hours Worked: $averageHours"

# Write the report to the file
try {
    $reportLines | Out-File -FilePath $outputPath -Encoding ASCII
    Write-Host "Report successfully written to $outputPath" -ForegroundColor Green
} catch {
    Write-Host "Failed to write the report. Error: $_" -ForegroundColor Red
}

<#
Author: Trae England
Student Number: n01520193
Description: This script populates an array with integers 1 through 10 using a loop,
prints the array in reverse order, and then alerts the user when the script is complete.
#>

# Declare an empty array
$numbers = @()

# Fill the array with values 1 through 10
for ($i = 1; $i -le 10; $i++) {
    $numbers += $i
}

# Print the array in reverse order
for ($j = $numbers.Count - 1; $j -ge 0; $j--) {
    Write-Output $numbers[$j]
}

# Show a message box to alert the user that the script is complete
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("Script is complete.", "Notice")

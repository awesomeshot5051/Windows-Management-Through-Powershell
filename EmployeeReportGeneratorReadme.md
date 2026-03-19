Script Name: EmployeeReportGenerator.ps1

Description:
This PowerShell script facilitates the collection of employee work data through an interactive console interface. It captures employee names and their respective weekly hours, performs statistical calculations for total and average time, and exports the finalized data into a professionally formatted ASCII text report.

How It Works:

Data Collection Loop: Prompts the user to enter an employee's name and initiates a data entry cycle.

Input Validation: Requests the number of hours worked and validates the input to ensure it is a non-negative integer; it will re-prompt the user if the data is invalid.

Dynamic Storage: Stores each entry as a custom PowerShell object within an array to maintain data integrity.

Statistical Calculation: Automatically tallies the total hours worked and calculates the average hours per employee, rounding the result to two decimal places.

Output Path Definition: Prompts the user to provide a full file path and filename for the generated report.

Report Generation: Constructs a structured report layout including individual line items for each employee and a summary section.

File Export: Writes the report to the disk using ASCII encoding and includes error handling to alert the user if the file cannot be saved due to path or permission issues.

Assumptions:

The user has the necessary filesystem permissions to write to the chosen output directory.

The hours worked are entered as whole numbers (integers).

The script is executed in an environment where PowerShell script execution is enabled (e.g., RemoteSigned or Unrestricted).

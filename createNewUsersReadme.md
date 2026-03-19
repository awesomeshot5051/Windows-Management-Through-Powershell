Script Name: createNewUsers-1.ps1

Description:
This PowerShell script automates the bulk onboarding of new employees into Active Directory. It reads user data from a CSV file, generates secure random passwords, manages Organizational Unit (OU) placement (including dynamic creation), and exports a final credential report for IT or HR distribution.

How It Works:

CSV Import and Path Resolution: Prompts for a "New Hires" CSV file and automatically handles both relative and absolute file paths.

Secure Password Generation: Utilizes a custom function to generate unique 15-character passwords featuring a mix of uppercase letters, numbers, and special characters.

Standardized Identity Logic: Automatically builds usernames following the firstinitial.lastname convention and converts names to lowercase for consistency.

Dynamic OU Management:

Constructs the target OU path based on the employee's department.

Verifies if the specific Department OU exists under OU=Users.

Interactively prompts the administrator to create missing OUs or fallback to the default "Users" container.

Active Directory Provisioning: Creates the user object with a User Principal Name (UPN) mapped to the england.local domain and enables the account immediately.

Security Compliance: Sets the "User must change password at next logon" flag to ensure individual account security upon first use.

Credential Logging: Exports a CreatedUsers.csv file to the same directory as the source, containing the new usernames and temporary passwords for record-keeping.

Assumptions:

Environment: The Active Directory PowerShell module is installed and the script is run from a domain-joined machine.

Permissions: The script is executed with administrative privileges (e.g., Domain Admin or delegated OU permissions).

Data Integrity: The input CSV file contains exactly three specific headers: Fname, Lname, and Department.


Example usage:
The file: [https://github.com/awesomeshot5051/Windows-Management-Through-Powershell/blob/master/NewHiresModule_7.csv](NewHiresModule_7.csv)

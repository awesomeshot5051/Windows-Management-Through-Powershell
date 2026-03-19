Script name: [OUCreation.ps1](https://github.com/awesomeshot5051/Windows-Management-Through-Powershell/blob/master/OUCreation.ps1)

# *Organizational Unit Manager – PowerShell Script*  
## Features  
- Create parent or child OUs  
- Batch-create OUs from a CSV file  
- Automatically handles missing parent OUs  
- Prompts for deletion protection  
- Clear the screen at any time using C  
- Supports default or custom domain name  
- Validates input and handles common errors  
## Prerequisites  
- Active Directory PowerShell module (Import-Module ActiveDirectory)  
- Must be run on a domain-joined machine with sufficient AD permissions  
- PowerShell version 5.1+ recommended  
- CSV file for bulk creation must be correctly formatted  
## How to Use  
- Run the script in PowerShell as Administrator.  
- You will be prompted to enter the domain name:  
- - Press Enter to use the automatically detected domain  
- - Or type a domain manually (e.g., corp.example.com)  
## Main Menu Options  
- 1) Create OU (parent/child)  
- 2) Create OUs from CSV file  
- 3) Delete OU (parent/child)  
- 4) Exit  
- C) Clear screen and show menu again  
## Create OU (Parent/Child)  
- Type parent or child when prompted.  
- For parent OUs, provide a name and whether it should be protected from deletion.  
- For child OUs:  
- - Specify how many parent OUs it has  
- - Enter each parent name in outermost-first order  
- - Enter the child OU name  
- - Confirm deletion protection  
## Create OUs from CSV File  
- You will be prompted for a path to your CSV file.  
- CSV Format (no headers required):  
- ChildOU,Parent1,Parent2,...  
- Example:  
- Janitors,Maintenance  
- Billing,HR,NorthAmerica  
- HelpDesk,IT,Support,Level1  
- - First column = Child OU name  
- - Remaining columns = Parent OUs, outermost to innermost  
## Delete OU (Parent/Child)  
- Choose to delete a parent or child OU.  
- For parent: provide OU name.  
- For child:  
- - Enter number of parent OUs  
- - Enter their names (outermost-first)  
- - Enter child OU name  
## Exit  
- Terminates the script with a farewell message.  
## Function Overview  
- Create-OU              – Create a parent or child OU manually  
- Create-OUsFromCSV      – Batch create OUs from a CSV file  
- Delete-OU              – Delete a parent or child OU  
- Ensure-ParentPathExists – Recursively creates missing parent OUs if needed  
- Get-BooleanInput       – Validates yes/no/true/false input  
- Exit-program           – Cleanly exits the script  
## Suggested Directory Structure  
- OUManager/  
- ├── OUManager.ps1  
- └── sample.csv  
## Example Output  
- Enter your domain name (press Enter for default: england.local):  
- 🔗 Using domain base DN: DC=england,DC=local  
-    
- 1) Create OU (parent/child)  
- 2) Create OUs from CSV file  
- 3) Delete OU (parent/child)  
- 4) Exit  
- C) Clear screen and show menu again  
- Enter your choice (1-4 or C): 1  
-    
- Is this a (parent) OU or a (child) OU? Type 'parent' or 'child': child  
- How many parent OUs does this child OU have?: 2  
- Enter name of parent OU #1 (outermost first): HR  
- Enter name of parent OU #2 (outermost first): NorthAmerica  
- Enter the name of the child OU: Billing  
- Is this object protected from deletion? (Yes/No/1/0/True/False): yes  
- ✅ Created child OU 'Billing' under 'OU=NorthAmerica,OU=HR,DC=england,DC=local'  
## Notes  
- Protected OUs cannot be deleted unless the protection flag is manually removed in Active Directory.  
- This script intentionally adds all OUs under Domain Controllers as a requirement (can be modified).  
- No support for renaming or moving OUs — only create/delete.  
## Troubleshooting  
- Import Errors: Ensure RSAT: Active Directory Tools are installed.  
- Permission Denied: Run as a user with AD permissions and elevated PowerShell.  
- CSV not importing: Check file encoding and format. Should be comma delimited.  
   

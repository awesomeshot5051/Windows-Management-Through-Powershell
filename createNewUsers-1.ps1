Import-Module ActiveDirectory

function Generate-RandomPassword {
    $pwd = ""
    for ($i = 0; $i -lt 15; $i++) {
        $choice = Get-Random -Minimum 0 -Maximum 3
        switch ($choice) {
            0 { $pwd += [char](Get-Random -Minimum 65 -Maximum 91) }       # A-Z (ASCII 65-90)
            1 { $pwd += [char](Get-Random -Minimum 33 -Maximum 48) }       # Special chars (ASCII 33-47)
            2 { $pwd += [char](Get-Random -Minimum 48 -Maximum 58) }       # 0-9 (ASCII 48-57)
        }
    }
    return $pwd
}

# Prompt for CSV path
$csvPath = Read-Host "Enter the path to your New Hires CSV file (full or relative)"

# Resolve relative path to full path
if (-not [System.IO.Path]::IsPathRooted($csvPath)) {
    $baseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    if (-not $baseDir) {
        $baseDir = (Get-Location).Path
    }
    $csvPath = Join-Path -Path $baseDir -ChildPath $csvPath
}

if (!(Test-Path $csvPath)) {
    Write-Host "❌ File not found at: $csvPath"
    exit
}

# Import CSV
$users = Import-Csv -Path $csvPath

$results = @()

foreach ($user in $users) {
    # Build username: first initial + "." + lastname lowercase
    $firstInitial = $user.Fname.Substring(0,1).ToLower()
    $lastName = $user.Lname.ToLower()
    $username = "$firstInitial.$lastName"

    $department = $user.Department

    # Build the OU path assuming structure: OU=Users,OU=Department,DC=england,DC=local
    $domainDN = (Get-ADDomain).DistinguishedName
    $usersOU = "OU=Users"
    $departmentOU = "OU=$department"

    $fullOUPath = "$usersOU,$departmentOU,$domainDN"

    Write-Host "Checking OU path: $fullOUPath"

    # Check if OU exists
    try {
        $ouObject = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$fullOUPath'" -ErrorAction Stop
        $ouExists = $true
    } catch {
        $ouExists = $false
    }

    # If OU does not exist, prompt user to create
    if (-not $ouExists) {
        Write-Host "⚠️ OU not found: $fullOUPath"
        $createOU = Read-Host "Do you want to create OU $departmentOU inside $usersOU? (Y/N)"
        if ($createOU -match '^[Yy]$') {
            try {
                # Create the department OU inside the Users OU
                $parentOUPath = "$usersOU,$domainDN"
                New-ADOrganizationalUnit -Name $department -Path $parentOUPath -ProtectedFromAccidentalDeletion $false
                Write-Host "✅ Created OU $departmentOU inside $usersOU"
                $ouExists = $true
            } catch {
                Write-Host "❌ Failed to create OU: $_"
                $ouExists = $false
            }
        }
    }

    # If OU still does not exist, ask if user should be created anyway (default container)
    if (-not $ouExists) {
        $createAnyway = Read-Host "OU does not exist. Create user $username in default Users container? (Y/N)"
        if ($createAnyway -match '^[Yy]$') {
            $fullOUPath = "CN=Users,$domainDN"
            Write-Host "User $username will be created in default Users container."
        } else {
            Write-Host "Skipping user $username creation due to missing OU."
            continue
        }
    }

    # Generate random password
    $passwordPlain = Generate-RandomPassword
    $securePassword = ConvertTo-SecureString $passwordPlain -AsPlainText -Force

    # Create user
    try {
        New-ADUser `
            -Name "$($user.Fname) $($user.Lname)" `
            -GivenName $user.Fname `
            -Surname $user.Lname `
            -SamAccountName $username `
            -UserPrincipalName "$username@england.local" `
            -AccountPassword $securePassword `
            -Path $fullOUPath `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Host "✅ Created user: $username"

        # Save result for export
        $results += [PSCustomObject]@{
            Fname      = $user.Fname
            Lname      = $user.Lname
            Username   = $username
            Password   = $passwordPlain
            Department = $department
        }

    } catch {
        Write-Warning "❌ Failed to create user: $username. Error: $_"
    }
}

# Export results CSV to same folder as input CSV
$outDir = [System.IO.Path]::GetDirectoryName($csvPath)
if ([string]::IsNullOrWhiteSpace($outDir)) {
    $outDir = (Get-Location).Path
}
$outPath = Join-Path -Path $outDir -ChildPath "CreatedUsers.csv"

$results | Export-Csv -Path $outPath -NoTypeInformation -Encoding UTF8

Write-Host "Finished! Created users and saved credentials to $outPath"

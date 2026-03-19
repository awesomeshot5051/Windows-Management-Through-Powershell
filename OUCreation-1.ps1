# === UPDATED SCRIPT ===
Import-Module ActiveDirectory -ErrorAction Stop

# Get the default domain (or fall back)
try {
    $defaultDomain = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name)
} catch {
    $defaultDomain = "england.local"
}

# Prompt for domain – if the user presses Enter, use the default.
while ($true) {
    $domainInput = Read-Host "Enter your domain name (press Enter for default: $defaultDomain)"
    if ([string]::IsNullOrWhiteSpace($domainInput)) {
        $domainName = $defaultDomain
        break
    } else {
        $domainName = $domainInput
        break
    }
}

# Convert domain to baseDN format
$baseDN = ($domainName -split '\.') | ForEach-Object { "DC=$_" }
$baseDN = $baseDN -join ","
Write-Host "🔗 Using domain base DN: $baseDN" -ForegroundColor Cyan

# -------------------
# Helper Functions
# -------------------
function Get-BooleanInput {
    param([string]$Prompt)
    while ($true) {
        $input = Read-Host $Prompt
        if ($input -match '^(yes|1|true)$') {
            return $true
        } elseif ($input -match '^(no|0|false)$') {
            return $false
        } else {
            Write-Host "Invalid input, try again." -ForegroundColor Yellow
        }
    }
}

# Ensure parent OUs exist before creating a child OU
function Ensure-ParentPathExists {
    param([string]$ouName, [string[]]$parents, [string]$baseDN)
    
    $currentPath = $baseDN  # Start at the domain root

    foreach ($segment in $parents) {
        if ($segment -match "^DC=") { continue }  # Skip any DCs (precaution)

        $parentPath = $currentPath
        $currentPath = "OU=$segment,$parentPath"


        # Check if this OU exists
        $exists = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$currentPath'" -ErrorAction SilentlyContinue
        if (-not $exists) {
            try {
                New-ADOrganizationalUnit -Name $segment -Path $parentPath -ProtectedFromAccidentalDeletion $true -ErrorAction Stop
                Write-Host "✅ Created missing parent OU '$segment' inside '$parentPath'" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to create parent OU '$segment': $_" -ForegroundColor Red
            }
        }
    }

    return $currentPath  # Final path to use for the child OU
}

# -------------------
# Create OU (Interactive)
# -------------------
function Create-OU {
    $ouType = Read-Host "Is this a (parent) OU or a (child) OU? Type 'parent' or 'child'"
    
    if ($ouType -eq "parent") {
        $ouName = Read-Host "Enter the name of the parent OU"
        $protected = Get-BooleanInput "Is this object protected from deletion? (Yes/No/1/0/True/False)"
        
        try {
            New-ADOrganizationalUnit -Name $ouName -Path $baseDN -ProtectedFromAccidentalDeletion $protected -ErrorAction Stop
            Write-Host "✅ Created parent OU '$ouName' under '$baseDN'" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to create parent OU: $_" -ForegroundColor Red
        }
    }
    elseif ($ouType -eq "child") {
        $numParents = Read-Host "How many parent OUs does this child OU have?"
        $parents = @()
        for ($i = 1; $i -le $numParents; $i++) {
            $parents += Read-Host "Enter name of parent OU #$i (outermost first)"
        }
        $childName = Read-Host "Enter the name of the child OU"
        
        # Reverse parents for correct nesting
        [array]::Reverse($parents)
        $parentDN = ($parents | ForEach-Object { "OU=$_" }) -join ","
        $ouPath = "$parentDN,$baseDN"
        Write-Host "🔎 Final DN path: OU=$childName,$ouPath" -ForegroundColor Yellow

        # Ensure parent OUs exist
        Ensure-ParentPathExists $ouPath

        $protected = Get-BooleanInput "Is this object protected from deletion? (Yes/No/1/0/True/False)"
        try {
            New-ADOrganizationalUnit -Name $childName -Path $ouPath -ProtectedFromAccidentalDeletion $protected -ErrorAction Stop
            Write-Host "✅ Created child OU '$childName' under '$ouPath'" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to create child OU: $_" -ForegroundColor Red
        }
    }
}

# -------------------
# Create OUs From CSV
# -------------------
function Create-OUsFromCSV {
    $csvPath = Read-Host "Enter full path to the CSV file"

    try {
        $entries = Import-Csv -Path $csvPath -Header ("ChildOU", "Parent1", "Parent2", "Parent3", "Parent4", "Parent5")
    } catch {
        Write-Host "❌ Failed to import CSV: $_" -ForegroundColor Red
        return
    }

    foreach ($entry in $entries) {
        $childName = $entry.ChildOU

        if ([string]::IsNullOrWhiteSpace($childName)) {
            Write-Host "⚠️ Skipping row due to missing child OU name." -ForegroundColor Yellow
            continue
        }

        # Build list of non-empty parent OUs
        $parentOUs = @($entry.Parent1, $entry.Parent2, $entry.Parent3, $entry.Parent4, $entry.Parent5) |
                     Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        # Reverse for correct nesting order
        [array]::Reverse($parentOUs)

        # Force 'Domain Controllers' into the hierarchy (at the base

        # Get domain base DN (from earlier)
        $fullOUPath = Ensure-ParentPathExists -ouName $childName -parents $fullParents -baseDN $baseDN

        $protected = Get-BooleanInput "Is '$childName' protected from deletion? (Yes/No/1/0/True/False)"
        try {
            New-ADOrganizationalUnit -Name $childName -Path $fullOUPath -ProtectedFromAccidentalDeletion $protected -ErrorAction Stop
            Write-Host "✅ Created OU '$childName' under '$fullOUPath'" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to create OU '$childName': $_" -ForegroundColor Red
        }
    }
}

# -------------------
# Delete OU Function
# -------------------
function Delete-OU {
    $ouType = Read-Host "Is the OU to delete a (parent) or (child)? Type 'parent' or 'child'"
    
    if ($ouType -eq "parent") {
        $ouName = Read-Host "Enter the name of the parent OU"
        $ouDN = "OU=$ouName,$baseDN"
        
        try {
            Remove-ADOrganizationalUnit -Identity $ouDN -Confirm:$false -ErrorAction Stop
            Write-Host "🗑️ Deleted parent OU: $ouDN" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error deleting parent OU: $_" -ForegroundColor Red
        }
    }
    elseif ($ouType -eq "child") {
        $numParents = Read-Host "How many parent OUs does this child OU have?"
        $parents = @()
        for ($i = 1; $i -le $numParents; $i++) {
            $parents += Read-Host "Enter name of parent OU #$i (outermost first)"
        }
        $childName = Read-Host "Enter the name of the child OU"

        [array]::Reverse($parents)
        $parentDN = ($parents | ForEach-Object { "OU=$_" }) -join ","
        $childDN = "OU=$childName,$parentDN,OU=Domain Controllers,$baseDN"

        try {
            Remove-ADOrganizationalUnit -Identity $childDN -Confirm:$false -ErrorAction Stop
            Write-Host "🗑️ Deleted child OU: $childDN" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error deleting child OU: $_" -ForegroundColor Red
        }
    }
}
function Exit-program{
Write-Host "Goodbye!" -ForegroundColor Cyan
Pause
exit
}

# -------------------
# MENU LOOP RESTORED
# -------------------
while ($true) {
    Write-Host ""
    Write-Host "1) Create OU (parent/child)"
    Write-Host "2) Create OUs from CSV file"
    Write-Host "3) Delete OU (parent/child)"
    Write-Host "4) Exit"
    Write-Host "C) Clear screen and show menu again"

    $choice = Read-Host "Enter your choice (1-4 or C)"

    switch ($choice.ToLower()) {
        "1" { Create-OU }
        "2" { Create-OUsFromCSV }
        "3" { Delete-OU }
        "4" { Exit-program }
        "c" {
            Clear-Host
            continue
        }
        default {
            Write-Host "❓ Invalid input. Please enter 1–4 or 'C'." -ForegroundColor Yellow
        }
    }
}



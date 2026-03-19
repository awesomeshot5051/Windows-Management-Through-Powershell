<#n01520193
Trae England#>
# Configure-Network.ps1
# Prompts user to set static IP, gateway, DNS, and rename the computer

function Select-NetworkAdapter {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if ($adapters.Count -eq 0) {
        Write-Host "No active network adapters found." -ForegroundColor Red
        exit
    }

    Write-Host "Available Network Adapters:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $adapters.Count; $i++) {
        Write-Host "$($i): $($adapters[$i].Name)"
    }

    $selection = Read-Host "Enter the number of the adapter to configure"
    if ($selection -notmatch '^\d+$' -or $selection -ge $adapters.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        exit
    }

    return $adapters[$selection].Name
}

# Prompt user for adapter
$adapterName = Select-NetworkAdapter

# Prompt user for static IP settings
$ipAddress = Read-Host "Enter the static IP address (e.g. 192.168.1.100)"
$subnetMask = Read-Host "Enter the subnet mask (e.g. 255.255.255.0)"
$gateway = Read-Host "Enter the default gateway (e.g. 192.168.1.1)"
$primaryDNS = Read-Host "Enter the primary DNS server"
$secondaryDNS = Read-Host "Enter the secondary DNS server (or leave blank if none)"

# Convert subnet mask to prefix length
function Convert-SubnetMaskToPrefix {
    param ($subnet)
    $binary = ($subnet -split '\.') | ForEach-Object {
        [Convert]::ToString([int]$_,2).PadLeft(8,'0')
    }
    return ($binary -join '').ToCharArray() | Where-Object { $_ -eq '1' } | Measure-Object | Select-Object -ExpandProperty Count
}

$prefixLength = Convert-SubnetMaskToPrefix $subnetMask

# Apply static IP
Try {
    # Remove existing IP addresses on the adapter
    $existingIPs = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($existingIPs) {
        foreach ($ip in $existingIPs) {
            Remove-NetIPAddress -InterfaceAlias $adapterName -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    # Remove existing default gateway(s) from the interface
    $existingGateways = Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
    if ($existingGateways) {
        foreach ($gw in $existingGateways) {
            Remove-NetRoute -InterfaceAlias $adapterName -DestinationPrefix $gw.DestinationPrefix -NextHop $gw.NextHop -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    # Now create the new IP address with the new default gateway
    New-NetIPAddress -InterfaceAlias $adapterName -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway -ErrorAction Stop

    Write-Host "Static IP applied successfully." -ForegroundColor Green
} Catch {
    Write-Host "Failed to apply static IP: $_" -ForegroundColor Red
    exit
}



# Set DNS servers
$dnsList = @($primaryDNS)
if ($secondaryDNS -ne "") {
    $dnsList += $secondaryDNS
}

Try {
    Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses $dnsList -ErrorAction Stop
    Write-Host "DNS servers configured." -ForegroundColor Green
} Catch {
    Write-Host "Failed to set DNS servers: $_" -ForegroundColor Red
    exit
}

# Rename computer
$newHostname = Read-Host "Enter the new hostname for this computer"
Try {
    Rename-Computer -NewName $newHostname -Force -ErrorAction Stop
    Write-Host "Computer renamed to $newHostname." -ForegroundColor Green
} Catch {
    Write-Host "Failed to rename computer: $_" -ForegroundColor Red
    exit
}

# Summary
Write-Host "`n--- Configuration Summary ---" -ForegroundColor Yellow
Write-Host "Adapter Name   : $adapterName"
Write-Host "IP Address     : $ipAddress"
Write-Host "Subnet Mask    : $subnetMask (/ $prefixLength)"
Write-Host "Gateway        : $gateway"
Write-Host "DNS Servers    : $($dnsList -join ', ')"
Write-Host "Computer Name  : $newHostname"
Write-Host "------------------------------`n"

# Reboot prompt
$reboot = Read-Host "Reboot now to apply hostname change? (Y/N)"
if ($reboot -match '^[Yy]$') {
    Restart-Computer
}

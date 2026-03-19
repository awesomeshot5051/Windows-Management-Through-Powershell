Script Name: Configure-Network.ps1
Description:
This PowerShell script allows a user to configure a static IP address, subnet mask, gateway, and DNS servers on a selected network adapter. It also allows the user to rename the computer and optionally reboot the system to apply the hostname change.

How It Works:

Lists all active network adapters and prompts the user to select one.

Prompts for static IP, subnet mask, default gateway, and DNS server addresses.

Converts the subnet mask to CIDR prefix length.

Clears any existing IP and gateway settings on the selected adapter.

Applies the new IP configuration and DNS settings.

Prompts the user to enter a new hostname and renames the computer.

Displays a summary of the configuration.

Optionally reboots the system to apply the hostname change.

Assumptions:

The script is run with administrator privileges.

The machine is using IPv4.

The provided IP information is valid and non-conflicting on the network.
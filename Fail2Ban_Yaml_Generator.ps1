# This script generates a .YAML file to block all the IP addresses within a specific subnet / CIDR notation
# Simply type the CIDR notation of the network you want to block and then copy the YAML from the YAML file into the homeassistant ip_bans.yaml
# Make sure to reload the YAML config or reboot home assistant to apply the change

function Check-CIDR ($subnetInput) {
    $ip = $subnetInput.Split('/')[0]
    $prefix = [int]$subnetInput.Split('/')[1]

    $subnetBytes = $ip.Split('.')
    $subnetInteger = [int]$subnetBytes[0]*16777216 + [int]$subnetBytes[1]*65536 + [int]$subnetBytes[2]*256 + [int]$subnetBytes[3]

    $networkInteger = [math]::Floor($subnetInteger / [math]::Pow(2, (32 - $prefix))) * [math]::Pow(2, (32 - $prefix))

    return $subnetInteger -eq $networkInteger
}

# Load StringBuilder from .NET
$sb = New-Object System.Text.StringBuilder

# Ask for subnet
do {
    $subnetInput = Read-Host -Prompt 'Input your subnet in CIDR notation (IE: 192.168.1.0/24)'
    if (-not (Check-CIDR $subnetInput)) {
        Write-Host "The CIDR notation is invalid. Please input a valid CIDR notation."
    }
} until (Check-CIDR $subnetInput)

$subnet = $subnetInput.Split('/')[0]
$prefix = [int]$subnetInput.Split('/')[1]

# Calculate the number of addresses in the subnet
$numberOfAddresses = [math]::Pow(2, (32 - $prefix))

# Convert the subnet to an integer
$subnetBytes = $subnet.Split('.')
$subnetInteger = [int]$subnetBytes[0]*16777216 + [int]$subnetBytes[1]*65536 + [int]$subnetBytes[2]*256 + [int]$subnetBytes[3]

# Get the current date
$date = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.ffffff+00:00'

# Iterate over each IP in the range
for ($i=0; $i -lt $numberOfAddresses-1; $i++){
    # Convert the IP back to a string
    $ipInteger = $subnetInteger + $i
    $ip = ([math]::Floor($ipInteger/16777216)).ToString() + '.' + 
          ([math]::Floor(($ipInteger%16777216)/65536)).ToString() + '.' + 
          ([math]::Floor(($ipInteger%65536)/256)).ToString() + '.' + 
          ($ipInteger%256).ToString()
    
    # Use StringBuilder for concatenation
    [void]$sb.AppendLine("${ip}:")
    [void]$sb.AppendLine("  banned_at: '$date'")
}

# Write output to file
$outFilePath = "banned_ips.yaml"
$sb.ToString() | Out-File -FilePath $outFilePath

# Check if file was successfully created
if (Test-Path $outFilePath) {
    Write-Host "The Fail2Ban YAML was successfully generated."
} else {
    Write-Host "Failed to generate the Fail2Ban YAML."
}

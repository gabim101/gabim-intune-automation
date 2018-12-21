<#
.SYNOPSIS 
This script is used to invoke action on a device
Script receives a managed device ID. This is converted in a nanaged device ID and an action is then invoked on the device
Parameters: deviceid and action
Actions supported : wipe retire delete sync
#>
[cmdletbinding()]
        param
        (
        [Parameter(Mandatory=$true)] $action,
        [Parameter(Mandatory=$true)] $DeviceID,
        [Parameter(Mandatory=$true)] $user
        )



Function Get-AuthToken-Pass {
[cmdletbinding()]

param
(

    [Parameter(Mandatory=$true)][string]$tenantName,
    [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$cred

)


try{
     return (Get-MSIntuneAuthToken -TenantName $tenantName -credential $cred)
    }

catch {
    write-output "Error Getting token" 
    }

}


Function Get-ManagedDevice(){

<#
.SYNOPSIS
This function is used to get Intune Managed Devices from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any Intune Managed Device
.EXAMPLE
Get-ManagedDevices
Returns all managed devices but excludes EAS devices registered within the Intune Service
.EXAMPLE
Get-ManagedDevices -IncludeEAS
Returns all managed devices including EAS devices registered within the Intune Service
.NOTES
NAME: Get-ManagedDevices
#>

[cmdletbinding()]

param
(
    $DeviceID
)

# Defining Variables
$graphApiVersion = "beta"
$Resource = "deviceManagement/managedDevices"
$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

try {


        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object -FilterScript {$_.id -eq $DeviceID}
    
    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}




Function Set-DeviceAction ()

{
<#
.SYNOPSIS
This function is used to invoke an action on an AAD device. 
Parameters: DeviceID and action
Actions supported : wipe retire delete sync
.EXAMPLE
Set-DeviceAction -action wipe -DeviceID $DeviceID

#>

   [cmdletbinding()]
   param
    (
        [Parameter(Mandatory=$true)] $action,
        [Parameter(Mandatory=$true)] $DeviceID
    ) 

    $graphApiVersion = "Beta"

    $dev = Get-ManagedDevice -DeviceID $DeviceID

    if ($dev)
    {

    try 
    {

        if($action -eq "wipe"){
            Write-output "Device " $dev.deviceName " will be wiped"
            $Resource = "deviceManagement/managedDevices/$DeviceID/wipe" 
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-output " Wiping the device"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post
        }

        if($action  -eq "retire'"){
            Write-output "Device " $dev.deviceName " will be retired"
            $Resource = "deviceManagement/managedDevices/$DeviceID/retire"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-output "Retiring the device"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

        }

        if($action -eq "delete"){
            Write-output "Device " $Dev.deviceName " will be deleted"
            $Resource = "deviceManagement/managedDevices('$DeviceID')"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-output "Deleting the device"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete

        }

        if($action -eq "sync"){
           Write-output "Device " $dev.deviceName " will be synced" 
           $Resource = "deviceManagement/managedDevices('$DeviceID')/syncDevice"
           $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
           write-output "Syncing the device"
           Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post
        }
    }

    catch 
    {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Output "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    break


    }  
    }  

    else {
        write-output "Invalid Device"
        }

}

######### END Set-DeviceAction


################### Start Main ####################
###################################################

# Import required modules
try {
    Import-Module -Name AzureAD -ErrorAction Stop
    Import-Module -Name PSIntuneAuth -ErrorAction Stop
}
catch {
    Write-Warning -Message "Failed to import modules"
}

$tenant="yourten.com"
$passfile="yourpass.pass"

$cred = Create-Cred -user $user -pfile $passfile
$authtoken = Get-AuthToken-Pass -tenantName $tenant -cred $cred


Set-DeviceAction  -action $action  -DeviceID $DeviceID

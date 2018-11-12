<#
.SYNOPSIS 
This script is used to verify enrolled devices in MDM and Azure. Runbook will be used on schedule and will calculate new 
joiners based on enrollemnt date 
PAramters are check inteval = how long back in time interval 
#>


[cmdletbinding()]
        param
        (
        [Parameter(Mandatory=$true)] $interval
        )
###########################
#### Create-Cred
##########################
function Create-Cred {
param
(

    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$pfile

)

$myCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $pfile | ConvertTo-SecureString)
return $myCred

}

#################################
## Get-AuthToken-Pass
#################################

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

#################################
## End-AuthToken-Pass
#################################

###################################
## Function Get-enrolled-devs
###################################

Function get-enrolled-devs {
    [cmdletbinding()]

    param 
        (
        [Parameter(Mandatory=$true)] $intervMin
        )




# Defining Variables
$graphApiVersion = "beta"
$Resource = "deviceManagement/managedDevices"


$checkTime=(get-date).AddMinutes($intervMin)
write-output "checkTime is "$checkTime

$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"


$devices = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

$retdevs =@()

if ($devices){

 #   $devices


    foreach ($dev in $devices ){
 
 # if ($dev.autopilotEnrolled = $true)
        if ($dev.managementState = 'managed'){
#            write-output "Device " $dev.devicename " enrollment time " $dev.enrolledDateTime
            if ( [datetime]$dev.enrolledDateTime -gt [datetime]$checkTime ){
                $retdevs = $retdevs += $dev
                write-output "New Device " $dev.devicename
            }
            
        }
        
    }

}

return $retdevs


}

######################################
#### End Get-enrolled-devices
######################################


# Import required modules
try {
    Import-Module -Name AzureAD -ErrorAction Stop
    Import-Module -Name PSIntuneAuth -ErrorAction Stop
  #  Import-Module -Name UnofficialIntuneManagement -ErrorAction Stop
}
catch {
    Write-Warning -Message "Failed to import modules"
}

$tenant="nttdsicsdemo.net"
$passfile="intune-automation.pass"
$user = "intune.automation@nttdsicsdemo.net"


$cred = Create-Cred -user $user -pfile $passfile
$authtoken = Get-AuthToken-Pass -tenantName $tenant -cred $cred


get-enrolled-devs -intervMin $interval

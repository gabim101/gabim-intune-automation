[cmdletbinding()]
param
(
    [Parameter(Mandatory=$true)][string]$VMName
)

function Create-SecurePass {

<#
.SYNOPSIS
This function is used to create user password and write it to disk securely
.DESCRIPTION
The function gets password and writes it on disk securely 
.EXAMPLE
Create-SecurePass
#>

[cmdletbinding()]

param
(

    [Parameter(Mandatory=$true)][string]$pfile
)

Read-Host "Enter Password" -AsSecureString |  ConvertFrom-SecureString | Out-File $pfile
}


function Create-Cred-fromFile {
param
(

    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$pfile

)

$myCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $pfile | ConvertTo-SecureString)
return $myCred

}

function Create-VM {
<#
.SYNOPSIS
This function is used to create a hyper-v VM
.DESCRIPTION
Create a Hyper-V VM. Chnage the parameters inside the function to customize the VM. At the end of the fucntion TPM is set and
boot disk is replace with gold image
#>
param
(
    [Parameter(Mandatory=$true)][string]$VMN,
    [parameter(Mandatory=$true)][string]$bootIMG
)

$NewVMParam = @{
  Name = $VMN
  Generation = 2
  MemoryStartUpBytes = 1GB
  Path = "c:\VMs"
  SwitchName =  "Ext"
  NewVHDPath =  "c:\VMs\$VMN\boot.vhdx"
  NewVHDSizeBytes =  50GB 
  ErrorAction =  'Stop'
  Verbose =  $True
  }

  $SetVMParam = @{
  ProcessorCount =  2
  DynamicMemory =  $True
  MemoryMinimumBytes =  1GB
  MemoryMaximumBytes =  3Gb
  ErrorAction =  'Stop'
  PassThru =  $True
  Verbose =  $True
  }

$VM = New-VM @NewVMParam 
$VM = $VM | Set-VM @SetVMParam 

##### Set TPM
$owner = Get-HgsGuardian UntrustedGuardian
$kp = New-HgsKeyProtector -Owner $owner -AllowUntrustedRoot
Set-VMKeyProtector -VMName $VMN -KeyProtector $kp.RawData
Enable-VMTPM -VMName $VMN

##### Copy gold image
$dst="c:\VMs\$VMN\boot.vhdx"
Write-Output "Copying Disk"
Copy-Item $bootIMG $dst
Write-Output "Starting $VMN"
Start-vm -Name $VMN
}

function Create-Cred {
<#
.SYNOPSIS
This function is used to create a credentiale based on user and password provieded as parameters
#>

param
(
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$password
)

$securePass = ConvertTo-SecureString $password -AsPlainText -Force
$myCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $securepass
return $myCred
}

Function Get-AuthToken-Pass {
<#
.SYNOPSIS
This function is used to create a authenticate token. Tenenat and credentials are parameters
#>
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

#########
### Main
#########


###### import required modules
Import-Module -Name AzureAD -ErrorAction Stop
Import-Module -Name PSIntuneAuth -ErrorAction Stop
Import-Module -Name WindowsAutoPilotIntune -ErrorAction Stop

###### set variables for Azure credentials

$AZuser="admin@M365xxxxxx.onmicrosoft.com"
$AZpfile ="c:\VMs\azureadmin.pass"
$AZten="M365xxxxxx.onmicrosoft.com"

####### Set variables for local admin on clone
$user = "marco"
$localpfile = "c:\VMs\admin.pass"

###### Create credentials, tokens and connecto to Intune
$localcred = Create-Cred-fromFile -user $user -pfile $localpfile
$AzCred = Create-Cred-fromFile -user $AZuser -pfile $AZpfile
$Token= Get-AuthToken-Pass -tenantName $AZten -cred $AzCred
$global:authToken = $Token
Connect-AutoPilotIntune -user $AZuser

#### create VM
Create-VM -bootIMG "c:\VMs\boot-gold.vhdx" -VMN $VMName

#### wait for clone to boot up and accept Powershell remote sessions
$file ="hwid.csv"

$session =$null
while ( $session -eq $null) {
    $session = New-PSSession -Credential $localcred -VMName $VMName -ErrorAction Ignore
    if ($session) { break}
    Write-Output "PS Session not ready. Retrying in 1 min "
    Start-Sleep -Seconds 60 
}

### get Autopilot information and upload it in Intune
$d =Invoke-Command -Session $session -command  { c:\powershell\get-ap-info.ps1 }  
Write-Output "Device Serial is $d.'Device Serial Number'"
Add-AutoPilotImportedDevice  -serialNumber $d.'Device Serial Number' -hardwareIdentifier $d.'Hardware Hash' -orderIdentifier "VMs"
Start-Sleep 20


#### wait for autopilot data to propagate in intune
$impdev = $null 
while ( $impdev -eq $null ){
$impdev = ( Get-AutoPilotDevice  |?{$_.serialNumber -eq $d.'Device Serial Number'}) 
if($impdev) 
{
 Write-Output "Device has been Imported"
 break
 }
Write-Output "Device has not been imported yet. Sleeping 2 min"
Invoke-AutopilotSync
Start-Sleep -Seconds 120 
}

$ProfileAssigned ="notAssigned"
while ($ProfileAssigned -like "notAssigned" -or $ProfileAssigned -like "*pending*"){
    $ProfileAssigned =  (Get-AutoPilotDevice|?{$_.serialNumber -eq $d.'Device Serial Number'}).deploymentProfileAssignmentStatus
    Write-Output "Profile has not been assigned yet. Sleeping 1 min"
    Start-Sleep -Seconds 60 
}

### Finaly the wait came to an end. We can wipe the device :D:D
 Write-Output "Invoking remote wipe of $VMName"
Invoke-Command -Session $session -command  { c:\powershell\start-wipe.bat } 

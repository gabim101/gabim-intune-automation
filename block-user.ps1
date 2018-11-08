[cmdletbinding()]
   param
    (
        [Parameter(Mandatory=$true)] $upn   
    ) 

function Block-User {
<#
.SYNOPSIS
This function is used to block an intune user. The function will check if the user is valid and then will block it 
 
Author: Gabriel Marculescu 


#>

[cmdletbinding()]
param
(

    [Parameter(Mandatory=$true)] $upn    
)


$user =  (Get-MsolUser | Where-Object UserprincipalName -EQ $upn)

if ($user){
    Write-Output "Blocking user $upn"
   
    try{
    Set-MsolUser -UserPrincipalName $upn -BlockCredential $true
    }

    catch {
    Write-Output "Cannot block user $upn"

    }
}
else {
    Write-Output "User $upn does not exist"
}
}

#################################
#### End Block-User
#################################


$ten="nttdsicsdemo.net"
$pf="intune-automation.pass"
$u="intune.automation@nttdsicsdemo.net"


#Create-SecurePass -pfile $pf
$c = Create-Cred -user $u -pfile $pf
Connect-MsolService -Credential $c

Block-User -upn $upn



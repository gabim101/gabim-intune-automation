<#
[cmdletbinding()]

param
(

    $JSON
    
)
#>


function Create-Cred {
param
(

    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$pfile

)

$myCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $pfile | ConvertTo-SecureString)
return $myCred

}



function Add-AADUser {
<#
.SYNOPSIS
This Runbook us used to create Msol users based on JSON Object and sends the inital password to manager 
Author: Gabriel Marculescu 
Aternate email address contains the manager email address for future references
Uncomment the parameter above if you want to sent the JSON as parameter 

#>

[cmdletbinding()]

param
(

    $JSON,
    $cred
    
)

$user = convertfrom-json $json 

Write-Output $user.userprincipalname


#Create User
try {
    $createuser = New-MsolUser -UserPrincipalName $user.userprincipalname -FirstName $user.givenName -LastName $user.surename -UsageLocation $user.usagelocation -DisplayName $user.displayName -LicenseAssignment $user.license -AlternateEmailAddresses $user.manageremail
}

catch {
write-error "Error creating user $user"
}

try {
    Add-MsolGroupMember -GroupObjectId (Get-MsolGroup | Where-Object DisplayName -eq $user.group).ObjectId -GroupMemberType User -GroupMemberObjectId  (Get-MsolUser | Where-Object UserprincipalName -eq $user.userprincipalname).ObjectId 
}
catch{
    write-error "Error adding user $AADuser to group "
}


#Email parameteres
$FromAddress="intune.automation@nttdsicsdemo.net"
$smtpserver = "smtp.office365.com"
$SmtpPort = '587'


$mailparam = @{
    To = $user.managerEmail
    From = $FromAddress
    Subject = "Welcome to NTT DATA ICS Demo"
    Body =@"

Dear $($user.displayname),

Congratulations and welcome to our company! We are so glad you have joined our team. This email contains your personal credentials* that is essential to beginning your journey with NTT DATA Services. 

Your Password is $($createuser.password) 

Regards,
Your Company Services Corporate IT Team.

"@
    SmtpServer = $smtpserver
    Port = $smtpport
    Credential = $cred
}

send-MailMessage @mailparam -UseSsl 
 

 }

#################################
#### End Add-AADUser
#################################


$ten="yourten.com"
$pf="youruser.pass"
$u="youruser@yourten.com"


#Create-SecurePass -pfile $pf
$c = Create-Cred -user $u -pfile $pf
Connect-MsolService -Credential $c



$USER =  @{
accountEnabled=$true;
displayName="Peter Parker";
userPrincipalName="Peter.Parker@yourten.com";
surname="Parker";
givenName="Peter";
usageLocation="US";
license="reseller-account:SPE_E3";
managerEmail="gabriel.marculescu@mydomain.com";
group="Finance";
requestID="12345"
}


 

$JSON_USER = ConvertTo-Json -InputObject $USER


Add-AADUser -JSON $JSON_USER -cred $c


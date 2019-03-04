# Define parameters for Microsoft Graph access token retrieval
    $client_id = "884ba9fd-7f77-4b3b-b1c6-clientID"
    $client_secret = "clientsecret" 
    $tenant_id = "3ecb1f77-fbf6-4349-8a55-tenantid"

    $resource = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$tenant_id"
    $tokenEndpointUri = "$authority/oauth2/token"
    $UserForDelegatedPermissions="admin@M365xtenant.onmicrosoft.com"
    $Password="adminpassword"

$content = "grant_type=password&client_id=$client_id&client_secret=$client_secret&username=$UserForDelegatedPermissions&password=$Password&resource=$resource";
$response = Invoke-RestMethod -Uri $tokenEndpointUri -Body $content -Method Post -UseBasicParsing
        
$access_token = $response.access_token

$testcallapps = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps"


$apps = Invoke-RestMethod   -Uri $testcallapps  -Headers @{"Authorization" = "Bearer $access_token"}   -ContentType "application/json"  -Method GET
<#               
               
$testCallUri1 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/e850f5c1-8023-4de4-8d62-4db79b7603d9/microsoft.graph.mobileLobApp/contentVersions/1/files/a931eef8-6201-4625-8682-317a8c8dad01" 
$body1 = Invoke-RestMethod   -Uri $testCallUri1  -Headers @{"Authorization" = "Bearer $access_token"}   -ContentType "application/json"  -Method GET     

$testCallUri2 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/32221302-c663-4dea-bc82-336453ffb517/microsoft.graph.mobileLobApp/contentVersions/1/files/33fa0e8b-4021-4e09-a01d-f9296fa80b92" 
$body2 = Invoke-RestMethod   -Uri $testCallUri2  -Headers @{"Authorization" = "Bearer $access_token"}   -ContentType "application/json"  -Method GET   

$testCallUriFlorin = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/e850f5c1-8023-4de4-8d62-4db79b7603d9/microsoft.graph.mobileLobApp/contentVersions/1/files/a931eef8-6201-4625-8682-317a8c8dad01" 
$florin =   Invoke-RestMethod   -Uri $testCallUriFlorin  -Headers @{"Authorization" = "Bearer $access_token"}   -ContentType "application/json"  -Method GET      
#> 

# gabim-intune-automation

This repository is created for intune automation

1. set-device-action is based on powershell-intune-samples repository 
 The script receives a managed device ID and an action. if device is valid, the action is executed
 Parameters deviceid and Action 
 Actions supported: wipe, retire, delete, sync 
 
2. Add-AADUser uses MSol module to create an intune user. Paramter is a json object. 
credentials are required. Password comes from and encrypted file 
 
 

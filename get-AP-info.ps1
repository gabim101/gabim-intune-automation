$file = "C:\powershell\hwid.csv"
Get-WindowsAutoPilotInfo.ps1 -OutputFile $file
Import-Csv  $file

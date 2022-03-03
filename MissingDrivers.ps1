#Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")  
$logFile = "$logPath\$($myInvocation.MyCommand).log"

#Start the logging 
Start-Transcript $logFile
Write-Host "Logging to $logFile"

#For formatting:
$result = @{Expression = {$_.Name}; Label = "Device Name"}, @{Expression = {$_.ConfigManagerErrorCode} ; Label = "Status Code" }, @{Expression = {$_.DeviceID} ; Label = "Device ID" }

#Checks for devices whose ConfigManagerErrorCode value is greater than 0, i.e has a problem device.
Get-WmiObject -Class Win32_PnpEntity | Where-Object {$_.ConfigManagerErrorCode -gt 0 } | Format-Table $result -AutoSize
#Put at the end to have results exported to a CSV file.
#| Export-CSV C:\Drivers.csv

#Gets motherboard manufacturer
$mobo = Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer

if (Get-WmiObject -Class Win32_PnpEntity | Where-Object {$_.ConfigManagerErrorCode -gt 0 }) {

    Write-Host "There are missing drivers"
    $mobo
    $result

} else {

    Write-Host "There are no missing drivers"

}

Stop-Transcript
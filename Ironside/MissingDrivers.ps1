#Gets motherboard manufacturer
$mobo = Get-WmiObject -Class Win32_BaseBoard
switch ($mobo.Manufacturer) {

    "ASUSTeK COMPUTER INC." {

        $mobo.Manufacturer = "ASUS"
        Write-Host "Detected" $mobo.Manufacturer "as motherboard manufacturer."
        Write-Host "Detected" $mobo.Product "as motherboard product name."

    }

    Default {

        Write-Host "Detected" $mobo.Manufacturer "as motherboard manufacturer. Short-name not currently known."
        Write-Host "Detected" $mobo.Product "as motherboard product name."

    }

}

#Result formatting
$result = @{Expression = {$_.Name}; Label = "Device Name"}, @{Expression = {$_.ConfigManagerErrorCode} ; Label = "Status Code" }, @{Expression = {$_.DeviceID} ; Label = "Device ID" }

#Checks for devices whose ConfigManagerErrorCode value is greater than 0, i.e has a problem device.
Get-WmiObject -Class Win32_PnpEntity | Where-Object {$_.ConfigManagerErrorCode -gt 0 } | Format-Table $result -AutoSize

if (Get-WmiObject -Class Win32_PnpEntity | Where-Object {$_.ConfigManagerErrorCode -gt 0 }) {

    Write-Host "There are missing drivers, please resolve and add to deployment."
    Pause

} else {

    Write-Host "There are no missing drivers. System is good to go."
    Start-Sleep -Seconds 5
    EXIT 0

}

#Put at the end to have results exported to a CSV file.
#| Export-CSV C:\Drivers.csv
#Sets the $Edition variable to the current 'Edition' of Windows installed to the local system
#so we know whether to get a key for Home or Pro.
$Edition = (Get-WmiObject win32_operatingsystem).caption

IF ($Edition -like "*10 Home")
{
	$Edition = "Home_10"
    Write-Output "Detected Windows 10 Home"
}
ELSEIF ($Edition -like "*10 Pro")
{
	$Edition = "Pro_10"
    Write-Output "Detected Windows 10 Pro"
}
ELSEIF ($Edition -like "*11 Home")
{
	$Edition = "Home_11"
    Write-Output "Detected Windows 11 Home"
}
ELSEIF ($Edition -like "*11 Pro")
{
	$Edition = "Pro_11"
    Write-Output "Detected Windows 11 Pro"
}
ELSE
{
    $Edition = $Edition+"?"
    Write-Output "What the ever-loving fuck is $Edition Chinesium Windows?"
    Write-Output "Fix your shit"
    PAUSE
    EXIT
}

#Sets the $Mobo variable to the current motherboard installed in the system. This is done
#so we know whether to use the MSI, ASUS, or any other injection tool.
$Mobo = Get-WmiObject -Class Win32_ComputerSystem | Select Manufacturer
$Mobo2 = Get-WmiObject -Class Win32_BaseBoard | Select Manufacturer

IF ($Mobo -like '*Micro-Star*')
{
    $Mobo = "MSI"
    Write-Output "Detected MSI Motherboard"
}
ELSEIF ($Mobo -like '*ASUS*')
{
    $Mobo = "ASUS"
    Write-Output "Detected ASUS Motherboard"
}
ELSEIF ($Mobo2 -like '*ASUS*')
{
    $Mobo = "ASUS"
    Write-Output "Detected ASUS Motherboard"
}
ELSEIF ($Mobo2 -like '*ASRock*')
{
    $Mobo = "ASRock"
    Write-Output "Detected ASRock Motherboard"
}
ELSE
{
    $Mobo = $Mobo+"."
    Write-Output "Yo, go get Ethan. This shit wack and saying it ain't ASUS or MSI."
    Write-Output "Instead, it thinks this motherboard was made by $Mobo "
    PAUSE
    EXIT
}

Start-Process -FilePath "C:\Applications\OA3\OA3.bat" $Edition,$Mobo -Verb RunAs -Wait

EXIT
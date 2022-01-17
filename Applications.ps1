<#

.DESCRIPTION
Automatic application installation

.AUTHOR
Ethan P. Schmidtke

.GITHUB


#>

<#

.TO DO

.MOTHERBOARDS
GIGABYTE RGB Fusion
ASRock Polychrome
ASUS Armoury Crate
MSI Center

.GRAPHICS CARDS
Precision X1
PNY VelocityX
Sapphire TRIXX
ZOTAC FireStorm
ASUS Armoury Crate
MSI Center

.SOUND CARDS
ASUS Xonar
Sound BlasterX AE-5

.COOLERS
Wraith Prism
iCUE

.MISC
Elgato
NZXT CAM
iRacing



.DONE

.MOTHERBOARDS

.GRAPHICS CARDS

.SOUND CARDS

.COOLERS

.MISC

#>

#Gather MDT variable(s)
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$DeployRoot = $TSEnv.Value("DeployRoot")

function Get-ChassisType {
<#

.DESCRIPTION
Get-ChassisType is used to determine whether or not the computer is a laptop or a desktop.

https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure?redirectedfrom=MSDN
Available values for chassis type:

Other (1)
Unknown (2)
Desktop (3)
Low Profile Desktop (4)
Pizza Box (5)
Mini Tower (6)
Tower (7)
Portable (8)
Laptop (9)
Notebook (10)
Hand Held (11)
Docking Station (12)
All in One (13)
Sub Notebook (14)
Space-Saving (15)
Lunch Box (16)
Main System Chassis (17)
Expansion Chassis (18)
SubChassis (19)
Bus Expansion Chassis (20)
Peripheral Chassis (21)
Storage Chassis (22)
Rack Mount Chassis (23)
Sealed-Case PC (24)
Tablet (30)
Convertible (31)
Detachable (32)

#>

    $chassisType = (Get-WmiObject -Class Win32_ComputerSystem).PCSystemType
    
    switch(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,30,31,32) {
        "1" {Write-Host "NOTICE: Chassis type 'Other' detected"; $chassisType = "Other"; Break}
        "2" {Write-Host "NOTICE: Chassis type 'Unknown' detected"; $chassisType = "Unknown"; Break}
        "3" {Write-Host "NOTICE: Chassis type 'Desktop' detected"; $chassisType = "Desktop"; Break}
        "4" {Write-Host "NOTICE: Chassis type 'Low Profile Desktop' detected"; $chassisType = "Low Profile Desktop"; Break}
        "5" {Write-Host "NOTICE: Chassis type 'Pizza Box' detected"; $chassisType = "Pizza Box"; Break}
        "6" {Write-Host "NOTICE: Chassis type 'Mini Tower' detected"; $chassisType = "Mini Tower"; Break}
        "7" {Write-Host "NOTICE: Chassis type 'Tower' detected"; $chassisType = "Tower"; Break}
        "8" {Write-Host "NOTICE: Chassis type 'Portable' detected"; $chassisType = "Portable"; Break}
        "9" {Write-Host "NOTICE: Chassis type 'Laptop' detected"; $chassisType = "Laptop"; Break}
        "10" {Write-Host "NOTICE: Chassis type 'Notebook' detected"; $chassisType = "Notebook"; Break}
        "11" {Write-Host "NOTICE: Chassis type 'Hand Held' detected"; $chassisType = "Hand Held"; Break}
        "12" {Write-Host "NOTICE: Chassis type 'Docking Station' detected"; $chassisType = "Docking Station"; Break}
        "13" {Write-Host "NOTICE: Chassis type 'All in One' detected"; $chassisType = "All in One"; Break}
        "14" {Write-Host "NOTICE: Chassis type 'Sub Notebook' detected"; $chassisType = "Sub Notebook"; Break}
        "15" {Write-Host "NOTICE: Chassis type 'Space-Saving' detected"; $chassisType = "Space-Saving"; Break}
        "16" {Write-Host "NOTICE: Chassis type 'Lunch Box' detected"; $chassisType = "Lunch Box"; Break}
        "17" {Write-Host "NOTICE: Chassis type 'Main System Chassis' detected"; $chassisType = "Main System Chassis"; Break}
        "18" {Write-Host "NOTICE: Chassis type 'Expansion Chassis' detected"; $chassisType = "Expansion Chassis"; Break}
        "19" {Write-Host "NOTICE: Chassis type 'SubChassis' detected"; $chassisType = "SubChassis"; Break}
        "20" {Write-Host "NOTICE: Chassis type 'Bus Expansion Chassis' detected"; $chassisType = "Bus Expansion Chassis"; Break}
        "21" {Write-Host "NOTICE: Chassis type 'Peripheral Chassis' detected"; $chassisType = "Peripheral Chassis"; Break}
        "22" {Write-Host "NOTICE: Chassis type 'Storage Chassis' detected"; $chassisType = "Storage Chassis"; Break}
        "23" {Write-Host "NOTICE: Chassis type 'Rack Mount Chassis' detected"; $chassisType = "Rack Mount Chassis"; Break}
        "24" {Write-Host "NOTICE: Chassis type 'Sealed-Case PC' detected"; $chassisType = "Sealed-Case PC"; Break}
        "30" {Write-Host "NOTICE: Chassis type 'Tablet' detected"; $chassisType = "Tablet"; Break}
        "31" {Write-Host "NOTICE: Chassis type 'Convertible' detected"; $chassisType = "Convertible"; Break}
        "32" {Write-Host "NOTICE: Chassis type 'Detachable' detected"; $chassisType = "Detachable"; Break}
    }

}

function Get-Shortcut {
<# 

.DESCRIPTION
Get-Shortcut is used to put a shortcut for a Windows Store App on the desktop dynamically

#>

    <#

    $TargetPath should be laid out as such; "shell:AppsFolder\(Target Path)!(App ID)"
    $ShortcutFile should be laid out as such; "$env:USERPROFILE\Desktop\(Program Name).lnk"

    The 'Target Path' for $TargetPath can be found by manually putting a shortcut for the desired
    application on the desktop and opening the 'Properties' tab. The 'Target Type' field is what you need.

    The 'App ID' can be found by going to the target folder for the app (Search the previously
    found 'Target Type' in File Explorer to find this) and opening the AppManifest.xml file.
    Once open, search for 'executable='. The App ID should be stored as 'ID = '

    #>
    $TargetPath =  "shell:AppsFolder\$Path!$AppID"
    $ShortcutFile = "$env:USERPROFILE\Desktop\$Name"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Save()

}

<# 

Checks the reported chassis of the system (Desktop/Laptop)
If the system is a laptop, it will install the laptop software and exit
If the system is a desktop the rest of the script will run, installing all necessary software

#>
Get-ChassisType {
    switch ($chassisType) {
        "Desktop" {Write-Host "NOTICE: System is a desktop, checking what software to install"; Break}
        "Laptop" {Write-Host "NOTICE: System is a laptop, installing software"; "NEED TO MAKE THIS INSTALL THE LAPTOP RGB SOFTWARE"; EXIT}
        Default {
            Write-Error "What the McFuck is the chassis type $chassisType"
            EXIT 0
        }
    }
}

$Mobo = Get-WmiObject -Class Win32_ComputerSystem | Select Manufacturer
$Mobo2 = Get-WmiObject -Class Win32_BaseBoard | Select Manufacturer

switch -Wildcard ($Mobo,$Mobo2) {
    "*Micro-Star*" {
        Write-Host "MSI Motherboard detected, installing MSI Center"
         & '$DeployRoot\Applications\Extra Software\Motherboards\MSI - MSI Center (1.0.36.0).exe' /Silent
         $Path = "9426MICRO-STARINTERNATION.MSICenter_kzh8wxbdkxb8p"
         $AppID = "App"
         $Name = "MSI Center.lnk"
         Get-Shortcut
        Break
    }
    "*ASUS*" {
        Write-Host "ASUS Motherboard detected, installing Armoury Crate"
         & '$DeployRoot\Applications\Extra Software\Motherboards\ASUS - Armoury Crate (3.0.11.0).exe' -Silent
         $Path = "B9ECED6F.ArmouryCrate_qmba6cd70vzyy"
         $AppID = "App"
         $Name = "Armoury Crate.lnk"
         Get-Shortcut
         $Path = "B9ECED6F.AURACreator_qmba6cd70vzyy"
         $AppID = "App"
         $Name = "Aura Creator.lnk"
         Get-Shortcut
        Break
    }
    "*ASRock*" {
        Write-Host "ASRock Motherboard detected, installing Polychrome RGB Sync"
         & '$DeployRoot\Applications\Extra Software\Motherboards\ASRock - Polychrome RGB (2.0.100).exe' /SILENT /NORESTART
         Rename-Item -Path "C:\Users\$ENV:USERNAME\Desktop\ASRRGBLED.lnk" -NewName "ASRock RGB.lnk"
        Break
    }
    "*GIGABYTE*" {
        Write-Host "GIGABYTE Motherboard detected, installing RGB Fusion"
         & '$DeployRoot\Applications\Extra Software\Motherboards\GIGABYTE - RGB Fusion (B21.0401.1)\setup.exe' /S /v/qn
        Break
    }
}

switch ($?) {
    "True" {Write-Host "NOTICE: Motherboard software installed sucessfully (Probably), continuing"; Break}
    "False" {Write-Error "Motherboard software failed to install (I think). Please find out why and try again."; EXIT 0}
}

$devices = [System.Collections.ArrayList]@(Get-PnpDevice -InstanceId '*')



switch -Wildcard ($devices.InstanceID) {
    #NZXT Smart Device V2
    #HID-Compliant Vendor-Defined Device
    "*VID_1E71&PID_2006&REV_0200*" {
        Write-Host "NOTICE: Detected NZXT Smart Device V2. Installing NZXT CAM."
         & '$DeployRoot\Applications\Extra Software\NZXT - CAM.exe'
    }

    #Corsair H100i
    #HID-Compliant Vendor-Defined Device
    "*VID_1B1C&PID_0C20&REV_0100*" {
        Write-Host "NOTICE: Detected Corsair H100i. Installing Corsair iCUE."
         & '$DeployRoot\Applications\Extra Software\Coolers\Corsair - iCUE (4.14.179).msi' /PASSIVE /NORESTART
    }

    #Elgato HD60 Pro
    #Sound, Video, and Game Controllers
    "*VEN_12AB&DEV_0380&SUBSYS_00061CFA&REV_00*" {
        Write-Host "NOTICE: Detected Elgato HD60 Pro. Installing Elgato software."
         & '$DeployRoot\Applications\Extra Software\4KCaptureUtility_1.7.4.4808_x64.msi' /PASSIVE /NORESTART
         & '$DeployRoot\Applications\Extra Software\GameCaptureSetup_3.70.51.3051_x64.msi' /PASSIVE /NORESTART
    }

    #Sound BlasterX AE-5 Plus
    #Sound, Video, and Game Controllers
    "*VEN_1102&DEV_0011&SUBSYS_1102019REV_1009*" {
        Write-Host "NOTICE: Detected Sound BlasterX AE-5 Plus. Installing Sound Blaster audio software."
         & '$DeployRoot\Applications\Extra Software\Sound Cards\Sound BlasterX AE-5 (3.4.92.00).exe' /SILENT /NORESTART
    }

    #
    #
    "**" {
        
    }

    #
    #
    "**" {
        
    }

    #
    #
    "**" {
        
    }

    #
    #
    "**" {
        
    }

    #
    #
    "**" {
        
    }
}
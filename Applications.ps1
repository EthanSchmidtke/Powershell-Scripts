<#

.DESCRIPTION
Automatic application installation

.AUTHOR
Ethan P. Schmidtke

.GITHUB


#>

#Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")  
$logFile = "$logPath\$($myInvocation.MyCommand).log"

#Start the logging 
Start-Transcript $logFile
Write-Host "Logging to $logFile"

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

function Get-GPU {
<# 

.DESCRIPTION
Get-GPU is used to get the vendor of the installed GPU (Intel, AMD, or NVIDIA) as well as
the model and manufacturer.

#>
    
    $GPUs = [System.Collections.ArrayList]@(Get-PnpDevice -Class 'Display')

    switch -wildcard ($GPUs.InstanceID) {

        #Integrated GPU
        "*&0&*" {Write-Host "NOTICE: Integrated GPU detected. Skipping and checking for dedicated GPU."}

        #NVIDIA GPU ID
        "*VEN_10DE*" {
            Write-Host "NOTICE: NVIDIA GPU Detected. Checking for board partner and installing latest driver."

            #Chassis Detection For GPU Driver
            switch ($chassisType) {
                "Desktop" {
                    Write-Host "NOTICE: $chassisType chassis detected. Installing NVIDIA desktop drivers."
                    & '\\SERVER-2\Test$\Applications\Software\GPU NVIDIA Desktop\NVIDIA.exe' -s -clean -noreboot -passive -noeula -nofinish
                }
                "Laptop" {
                    Write-Host "NOTICE: $chassisType chassis detected. Installing NVIDIA laptop drivers."
                    & '\\SERVER-2\Test$\Applications\Software\GPU NVIDIA Laptop\NVIDIA.exe' -s -clean -noreboot -passive -noeula -nofinish
                }
                Default {Write-Error "Yo, this system isn't a desktop or laptop. What is $chassisType and why is it being reported as one?"; EXIT 0}
            }

            #GPU Board Partner Detection
            switch -wildcard ($GPUs.InstanceID) {
                #ASUS ID
                "*1043*" {
                    Write-Host "NOTICE: ASUS GPU Detected. Installing Armoury Crate."
                    & '\\SERVER-2\Test$\Applications\Software\ASUS Armoury Crate.exe' -Silent
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
                #EVGA ID
                "*3842*" {
                    Write-Host "NOTICE: EVGA GPU Detected. Installing Precision X1."
                    & '\\SERVER-2\Test$\Applications\Software\EVGA Precision X1.exe' /S
                    Break
                }
                #MSI ID
                "*1462*" {
                    Write-Host "NOTICE: MSI GPU Detected. Installing MSI Center."
                    & '\\SERVER-2\Test$\Applications\Software\MSI Center.exe' /Silent
                    $Path = "9426MICRO-STARINTERNATION.MSICenter_kzh8wxbdkxb8p"
                    $AppID = "App"
                    $Name = "MSI Center.lnk"
                    Get-Shortcut
                    Break
                }
                #PNY ID
                "*196E*" {
                    Write-Host "NOTICE: PNY GPU Detected. Installing VelocityX."
                    & '\\SERVER-2\Test$\Applications\Software\PNY VelocityX.exe' /SILENT /NORESTART
                    New-Item -ItemType SymbolicLink -Path "C:\Users\$ENV:Username\Desktop\VelocityX.lnk" -Target "C:\Program Files\VelocityX\VelocityX.exe"
                    Break
                }
                #ZOTAC ID
                "*19DA*" {
                    Write-Host "NOTICE: ZOTAC GPU Detected. Installing Firestorm."
                    & '\\SERVER-2\Test$\Applications\Software\ZOTAC Firestorm.exe' /SILENT /NORESTART
                    Break
                }
                #GIGABYTE ID
                "*1458*" {
                    Write-Host "NOTICE: GIGABYTE GPU Detected. Installing RGB Fusion."
                    & '\\SERVER-2\Test$\Applications\Software\GIGABYTE RGB Fusion.exe' /S /v/qn
                    Break
                }

                Default {Write-Error "Unknown NVIDIA GPU Detected. Please resolve."; EXIT 0}

            }
        }

        #AMD GPU ID
        "*VEN_1002**&1&*" {
            
            #GPU Driver
            Write-Host "NOTICE: AMD GPU Detected. Checking for board partner and installing latest driver."
            & '\\SERVER-2\Test$\Applications\Software\GPU AMD\Setup.exe' -INSTALL -OUTPUT detail
            New-Item -ItemType SymbolicLink -Path "C:\Users\$ENV:Username\Desktop\Radeon Software.lnk" -Target "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe"
            
            #GPU Board Partner Detection
            switch -wildcard ($GPUs.InstanceID) {
                #ASUS ID
                "*1043*" {
                    Write-Host "NOTICE: ASUS GPU Detected. Installing Armoury Crate."
                    & '\\SERVER-2\Test$\Applications\ASUS Armoury Crate.exe' -Silent
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
                #SAPPHIRE ID
                "*1DA2*" {
                    Write-Host "NOTICE: SAPPHIRE GPU Detected. Installing TriXX."
                    & '\\SERVER-2\Test$\Applications\Software\SAPPHIRE TRIXX.exe' /SILENT /NORESTART
                    Copy-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Sapphire TRIXX.lnk" -Destination "C:\Users\$ENV:Username\Desktop\TRiXX.lnk"
                    Break
                }
                Default {Write-Error "Unknown AMD GPU Detected. Please resolve."; EXIT 0}
            }
        }

        Default {Write-Error "$GPUs Was the detected GPU. Either one is not installed or this model is unknown. Figure it out."; EXIT 0}

    }
}

Get-ChassisType {
<# 

.DESCRIPTION Checks the reported chassis of the system (Desktop/Laptop)
If the system is a laptop, it will install the laptop software and exit
If the system is a desktop the rest of the script will run, installing all necessary software

#>
    switch ($chassisType) {
        
        "Desktop" {Write-Host "NOTICE: System is a desktop, checking what software to install."; Break}
        "Laptop" {
            Write-Host "NOTICE: System is a laptop, installing Intel NUC software."
            winget install --id 9NT0ZDV64HTC --silent --force --accept-package-agreements --accept-source-agreements
            EXIT
        }
        
        Default {
            Write-Error "What the McFuck is the chassis type $chassisType"
            EXIT 0
        }

    }
}

#Good chance the first $Mobo variable is not needed as every board I am aware of reports
#its brand under Win32_BaseBoard Manufacturer. Need to test this theory to be sure.
$Mobo = Get-WmiObject -Class Win32_ComputerSystem | Select-Object Manufacturer
$Mobo2 = Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer

#Motherboards
switch -Wildcard ($Mobo,$Mobo2) {
    
    #MSI Motherboard
    "*Micro-Star*" {
        Write-Host "NOTICE: MSI Motherboard detected, installing MSI Center."
         & '\\SERVER-2\Test$\Applications\Software\MSI Center.exe' /Silent
         $Path = "9426MICRO-STARINTERNATION.MSICenter_kzh8wxbdkxb8p"
         $AppID = "App"
         $Name = "MSI Center.lnk"
         Get-Shortcut
        Break
    }

    #ASUS Motherboard
    "*ASUS*" {
        Write-Host "NOTICE: ASUS Motherboard detected, installing Armoury Crate"
         & '\\SERVER-2\Test$\Applications\Software\ASUS Armoury Crate.exe' -Silent
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

    #ASRock Motherboard
    "*ASRock*" {
        Write-Host "NOTICE: ASRock Motherboard detected, installing Polychrome RGB Sync."
         & '\\SERVER-2\Test$\Applications\Software\ASRock Polychrome RGB.exe' /SILENT /NORESTART
         Rename-Item -Path "C:\Users\$ENV:USERNAME\Desktop\ASRRGBLED.lnk" -NewName "ASRock RGB.lnk"
        Break
    }

    #GIGABYTE Motherboard
    "*GIGABYTE*" {
        Write-Host "NOTICE: GIGABYTE Motherboard detected, installing RGB Fusion."
         & '\\SERVER-2\Test$\Applications\Software\GIGABYTE RGB Fusion\setup.exe' /S /v/qn
        Break
    }
}

#GPUs
Get-GPU

#Check for Corsair RAM - No better way to detect it right now
$RAM = Get-WMIObject Win32_PhysicalMemory | Format-Table Manufacturer

switch ($RAM) {

    "Corsair" {
        Write-Host "NOTICE: Corsair RAM detected. We currently only sell RGB Corsair RAM, so Corsair iCUE is being installed."
         & '\\SERVER-2\Test$\Applications\Software\iCUE.msi' /QUIET
         Copy-Item 'C:\ProgramData\Microsoft\Windows\Start Menu\Corsair\iCUE.lnk' -Destination 'C:\Users\$ENV:Username\Desktop'
         Break
    }

    Default {Write-Host "NOTICE: Non-Corsair RAM detected. Skipping iCUE...for now."; Break}

}

#Detects all installed system devices (drivers) and pipes them into a variable
$devices = [System.Collections.ArrayList]@(Get-PnpDevice -InstanceId '*')

#Misc. system devices
switch -Wildcard ($devices.InstanceID) {

    #NZXT Smart Device V2
    #HID-Compliant Vendor-Defined Device
    "*VID_1E71&PID_2006&REV_0200*" {
        Write-Host "NOTICE: Detected NZXT Smart Device V2. Installing NZXT CAM."
         & '\\SERVER-2\Test$\Applications\Software\NZXT CAM.exe'
    }

    #Corsair H100i
    #HID-Compliant Vendor-Defined Device
    "*VID_1B1C&PID_0C20&REV_0100*" {
        Write-Host "NOTICE: Detected Corsair H100i. Installing Corsair iCUE."
         & '\\SERVER-2\Test$\Applications\Software\iCUE.msi' /QUIET
         Copy-Item 'C:\ProgramData\Microsoft\Windows\Start Menu\Corsair\iCUE.lnk' -Destination 'C:\Users\$ENV:Username\Desktop'
    }

    #Elgato HD60 Pro
    #Sound, Video, and Game Controllers
    "*VEN_12AB&DEV_0380&SUBSYS_00061CFA&REV_00*" {
        Write-Host "NOTICE: Detected Elgato HD60 Pro. Installing Elgato software."
         & '\\SERVER-2\Test$\Applications\Software\Elgato HD60Pro\4KCaptureUtility.msi' /PASSIVE /NORESTART
         & '\\SERVER-2\Test$\Applications\Software\Elgato HD60Pro\GameCaptureSetup.msi' /PASSIVE /NORESTART
    }

    #Sound BlasterX AE-5 Plus
    #Sound, Video, and Game Controllers
    "*VEN_1102&DEV_0011&SUBSYS_1102019REV_1009*" {
        Write-Host "NOTICE: Detected Sound BlasterX AE-5 Plus. Installing Sound Blaster audio software."
         & '\\SERVER-2\Test$\Applications\Software\Sound BlasterX.exe' /SILENT /NORESTART
    }

    #Wraith Prism
    #USB Composite Device
    "*VID_2516&PID_0051*" {
        Write-Host "NOTICE: Detected Wraith Prism cooler. Installing Cooler Master RGB software."
         Copy-Item '\\SERVER-2\Test$\Applications\Software\Wraith Prism' -Destination 'C:\Program Files (x86)'
         Move-Item 'C:\Program Files (x86)\Wraith Prism\Wraith Prism.lnk' -Destination 'C:\Users\$ENV:Username\Desktop'
    }
    
    Default {
        Write-Host "NOTICE: No RGB devices detected in the system. Proceeding with Windows install."
        Write-Error "Recorded system devices:"
        Write-Host "$devices"
        Write-Error "End of list."    
        Break
    }

}

#iRacing Installation
switch -Wildcard ($ENV:Computername) {

    #Uses the computers name to detect if iRacing software is needed or not
    "*-iRacing*" {
        Write-Host "NOTICE: Computer name includes iRacing. Will now install all required iRacing files."
        & '\\SERVER-2\Test$\Applications\Software\iRacing\Driver.exe' /S /v/qn
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2012_redist_x64.exe' /install /passive /norestart
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2012_redist_x86.exe' /install /passive /norestart
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2013_redist_x64.exe' /install /passive /norestart
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2013_redist_x86.exe' /install /passive /norestart
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2015_redist_x64.exe' /install /passive /norestart
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2015_redist_x86.exe' /install /passive /norestart
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2017_redist_x64.exe' /install /passive /norestart
        & '\\SERVER-2\Test$\Applications\Software\iRacing\vc2017_redist_x86.exe' /install /passive /norestart
        Enable-WindowsOptionalFeature -NoRestart -Online -FeatureName "NetFx3"
        Copy-Item "\\SERVER-2\Test$\Applications\Software\iRacing\EasyAntiCheat" -Destination "C:\Program Files (x86)"
        Copy-Item "\\SERVER-2\Test$\Applications\Software\iRacing\iRacing" -Destination "C:\Program Files (x86)"
        Copy-Item "\\SERVER-2\Test$\Applications\Software\iRacing\Shortcuts\*" -Destination "C:\Users\$ENV:Username\Desktop"
        Break
    }

    Default {Write-Host "NOTICE: This computer does not contain 'iRacing' in the name. Skipping software install."; Break}

}

#Stops logging
Stop-Transcript

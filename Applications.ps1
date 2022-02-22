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
Start-Transcript -Path "$logFile"
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

function Start-Install {
<# 

.DESCRIPTION
Start-Install contains the necessary code to install all software with their required switches. This will
help clean up the code for the script.

#>

Try {

    Start-Process "$InstallLocation" -ArgumentList "$Arguments" -Wait

} Catch {

    #Catch will pick up any non zero error code returned. You can do anything you like in this block to deal with the error, examples below:
    #$_ returns the error details. This will just write the error.
    Write-Host "$ApplicationName returned the following error $_"

    #If you want to pass the error upwards as a system error and abort your powershell script or function
    Throw "Aborted $ApplicationName returned $_"

}

}

function Get-GPU {
<# 

.DESCRIPTION
Get-GPU is used to get the vendor of the installed GPU (Intel, AMD, or NVIDIA) as well as
the model and manufacturer.

#>
    
    $GPUs = [System.Collections.ArrayList]@(Get-PnpDevice -Class 'Display')

    Switch -wildcard ($GPUs.InstanceID) {

        #Integrated GPU
        "*&0&*" {

            Write-Host "NOTICE: Integrated GPU detected. Hardware ID ($_). Skipping and checking for dedicated GPU."

        }

        #NVIDIA GPU ID
        "*VEN_10DE*" {

            Write-Host "NOTICE: NVIDIA GPU Detected. Checking for board partner and installing software."

            #GPU Board Partner Detection
            switch -wildcard ($GPUs.InstanceID) {

                #ASUS ID
                "*1043*" {

                    Write-Host "NOTICE: ASUS GPU Detected. Checking if 'known' GPU."
                    #PCI\VEN_10DE&DEV_21C4&SUBSYS_877E1043&REV_A1\4&34A42055&0&0008

                    Switch -Wildcard ($_) {
                        
                        #Non-RGB GPUs
                        "*877E*" {
                        
                            Write-Host "NOTICE: Non-RGB ASUS GPU detected. Skipping Armoury Crate installation."
                            Break
                        
                        }
                        "*885E*" {
                        
                            Write-Host "NOTICE: Non-RGB ASUS GPU detected. Skipping Armoury Crate installation."
                            Break
                        
                        }

                        #RGB GPUs
                        "ASUS GPU with RGB" {
                        
                            $InstallLocation = "C:\Applications\Extra Software\ASUS Armoury Crate.exe"
                            $Arguments = "-Silent"
                            $ApplicationName = "Armoury Crate"
                            Start-Install
                    
                            While (!(Test-Path "C:\Program Files\ASUS\ARMOURY CRATE Lite Service" -ErrorAction SilentlyContinue)) {
                        
                                Write-Host "Armoury Crate still installing. Checking again in 30 seconds."
                                Start-Sleep -Seconds 30
                        
                            }

                            Write-Host "ASUS Software appears to be installed. Continuing."

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

                        Default {
                        
                            Write-Host "NOTICE: Unknown ASUS GPU detected. Go grab Ethan."
                            PAUSE
                        
                        }
                    
                    }

                    Break

                }

                #EVGA ID
                "*3842*" {

                    Write-Host "NOTICE: EVGA GPU Detected. Installing Precision X1."

                    $InstallLocation = "C:\Applications\Extra Software\EVGA Precision X1.exe"
                    $Arguments = "/S"
                    $ApplicationName = "Precision X1"
                    Start-Install

                    Copy-Item -Path "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\EVGA\EVGA Precision X1.lnk" -Destination "C:\Users\$ENV:Username\Desktop"
                    Break

                }

                #MSI ID
                "*1462*" {

                    Write-Host "NOTICE: MSI GPU Detected. Installing MSI Center."

                    $InstallLocation = "C:\Applications\Extra Software\MSI Center.exe"
                    $Arguments = "/Silent"
                    $ApplicationName = "MSI Center"
                    Start-Install

                    $Path = "9426MICRO-STARINTERNATION.MSICenter_kzh8wxbdkxb8p"
                    $AppID = "App"
                    $Name = "MSI Center.lnk"
                    Get-Shortcut
                    Break

                }

                #PNY ID
                "*196E*" {

                    Write-Host "NOTICE: PNY GPU Detected. Installing VelocityX."

                    $InstallLocation = "C:\Applications\Extra Software\PNY VelocityX.exe"
                    $Arguments = "/SILENT /NORESTART"
                    $ApplicationName = "PNY VelocityX"
                    Start-Install

                    New-Item -ItemType SymbolicLink -Path "C:\Users\$ENV:Username\Desktop\VelocityX.lnk" -Target "C:\Program Files\VelocityX\VelocityX.exe"
                    Break

                }

                #ZOTAC ID
                "*19DA*" {

                    Write-Host "NOTICE: ZOTAC GPU Detected. Installing Firestorm."

                    $InstallLocation = "C:\Applications\Extra Software\ZOTAC Firestorm.exe"
                    $Arguments = "/SILENT /NORESTART"
                    $ApplicationName = "ZOTAC Firestorm"
                    Start-Install

                    Break

                }

                #GIGABYTE ID
                "*1458*" {

                    Write-Host "NOTICE: GIGABYTE GPU Detected. Installing RGB Fusion."

                    $InstallLocation = "C:\Applications\Extra Software\GIGABYTE RGB Fusion.exe"
                    $Arguments = "/S /v/qn"
                    $ApplicationName = "GIGABYTE RGB Fusion"
                    Start-Install

                    Break

                }

                Default {
                
                    Write-Host "Unknown NVIDIA GPU Detected. Please resolve."
                    EXIT 0
                
                }

            }

        }

        #AMD GPU ID
        "*VEN_1002**&1&*" {

            #GPU Board Partner Detection
            switch -wildcard ($GPUs.InstanceID) {
            
                #ASUS ID
                "*1043*" {
                
                    Write-Host "NOTICE: ASUS GPU Detected. Checking if 'known' GPU."
                    #PCI\VEN_10DE&DEV_21C4&SUBSYS_877E1043&REV_A1\4&34A42055&0&0008

                    Switch -Wildcard ($_) {
                        
                        #Non-RGB GPUs
                        "ASUS GPU without RGB" {
                        
                        Write-Host "NOTICE: Non-RGB ASUS GPU detected. Skipping Armoury Crate installation."
                        Break
                        
                        }

                        #RGB GPUs
                        "ASUS GPU with RGB" {
                        
                            $InstallLocation = "C:\Applications\Extra Software\ASUS Armoury Crate.exe"
                            $Arguments = "-Silent"
                            $ApplicationName = "Armoury Crate"
                            Start-Install
                    
                            While (!(Test-Path "C:\Program Files\ASUS\ARMOURY CRATE Lite Service" -ErrorAction SilentlyContinue)) {
                        
                                Write-Host "Armoury Crate still installing. Checking again in 30 seconds."
                                Start-Sleep -Seconds 30
                        
                            }

                            Write-Host "ASUS Software appears to be installed. Continuing."

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

                        Default {
                        
                            Write-Host "NOTICE: Unknown ASUS GPU detected. Go grab Ethan."
                            PAUSE
                        
                        }
                    
                    }

                    Break
                
                }
                
                #SAPPHIRE ID
                "*1DA2*" {

                    Write-Host "NOTICE: SAPPHIRE GPU Detected. Installing TriXX."

                    $InstallLocation = "C:\Applications\Extra Software\SAPPHIRE TRIXX.exe"
                    $Arguments = "/SILENT /NORESTART"
                    $ApplicationName = "SAPPHIRE TriXX"
                    Start-Install

                    Copy-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Sapphire TRIXX.lnk" -Destination "C:\Users\$ENV:Username\Desktop\TRiXX.lnk"
                    Break

                }

                Default {

                    Write-Host "Unknown AMD GPU Detected. Please resolve."
                    EXIT 0

                }
            
            }

        }

        Default {
            
            Write-Host "$GPUs Was the detected GPU. Either one is not installed or this model is unknown. Figure it out."
            EXIT 0
        
        }

    }
    
}

#Pre-emptively update all available packages. Not really necessary but we may as well.
WINGET Upgrade --All --Silent --Accept-Package-Agreements --Accept-Source-Agreements

Get-ChassisType {
<# 

.DESCRIPTION Checks the reported chassis of the system (Desktop/Laptop)
If the system is a laptop, it will install the laptop software and exit
If the system is a desktop the rest of the script will run, installing all necessary software

#>

    switch ($chassisType) {
        
        "Desktop" {
        
            Write-Host "NOTICE: System is a desktop, checking what software to install."
            Break
        
        }

        "Other" {

            Write-Host "NOTICE: System is a desktop, checking what software to install."
            Break

        }

        "Laptop" {

            Write-Host "NOTICE: System is a laptop, installing Intel NUC software."
            winget install --id 9NT0ZDV64HTC --silent --force --accept-package-agreements --accept-source-agreements
            EXIT

        }
        
        Default {

            Write-Host "What the McFuck is the chassis type $chassisType"
            EXIT 0

        }

    }

}

#Good chance the first $Mobo variable is not needed as every board I am aware of reports
#its brand under Win32_BaseBoard Manufacturer. Need to test this theory to be sure.
$Mobo = Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer

#Motherboards
switch -Wildcard ($Mobo) {
    
    #MSI Motherboard
    "*Micro-Star*" {

        Write-Host "NOTICE: MSI Motherboard detected, installing MSI Center."

        $InstallLocation = "C:\Applications\Extra Software\MSI Center.exe"
        $Arguments = "/Silent"
        $ApplicationName = "MSI Center"
        Start-Install
        
        $Path = "9426MICRO-STARINTERNATION.MSICenter_kzh8wxbdkxb8p"
        $AppID = "App"
        $Name = "MSI Center.lnk"
        Get-Shortcut
        Break

    }

    #ASUS Motherboard
    "*ASUS*" {

        Write-Host "NOTICE: ASUS Motherboard detected, installing Armoury Crate"

        $InstallLocation = "C:\Applications\Extra Software\ASUS Armoury Crate.exe"
        $Arguments = "-Silent"
        $ApplicationName = "Armoury Crate"
        Start-Install
                    
        While (!(Test-Path "C:\Program Files\ASUS\ARMOURY CRATE Lite Service" -ErrorAction SilentlyContinue)) {
                        
            Write-Host "Armoury Crate still installing. Checking again in 30 seconds."
            Start-Sleep -Seconds 30
                        
        }

        Write-Host "ASUS Software appears to be installed. Continuing."

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

        $InstallLocation = "C:\Applications\Extra Software\ASRock Polychrome RGB.exe"
        $Arguments = "/SILENT /NORESTART"
        $ApplicationName = "ASRock Polychrome RGB Sync"
        Start-Install
         
        Rename-Item -Path "C:\Users\$ENV:USERNAME\Desktop\ASRRGBLED.lnk" -NewName "ASRock RGB.lnk"
        Break

    }

    #GIGABYTE Motherboard
    "*GIGABYTE*" {

        Write-Host "NOTICE: GIGABYTE Motherboard detected, installing RGB Fusion."

        $InstallLocation = "C:\Applications\Extra Software\GIGABYTE RGB Fusion\setup.exe"
        $Arguments = "/S /v/qn"
        $ApplicationName = "GIGABYTE RGB Fusion"
        Start-Install

        Break

    }

}

#GPUs
Get-GPU

#Check for Corsair RAM - No better way to detect it right now
$RAM = Get-WMIObject Win32_PhysicalMemory | Select-Object Manufacturer

Switch -Wildcard ($RAM) {

    "*Corsair*" {

        Write-Host "NOTICE: Corsair RAM detected. We currently only sell RGB Corsair RAM, so Corsair iCUE is being installed."

        WINGET Install --ID Corsair.iCUE.4 --Silent --Accept-Package-Agreements --Accept-Source-Agreements

        Copy-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Corsair\iCUE.lnk" -Destination "C:\Users\$ENV:Username\Desktop"
        Break

    }

    Default {
        
        Write-Host "NOTICE: Non-Corsair RAM detected. Skipping iCUE...for now."
        Break
    
    }

}

#Detects all installed system devices (drivers) and pipes them into a variable
$devices = [System.Collections.ArrayList]@(Get-PnpDevice -InstanceId '*')

#Misc. system devices
Switch -Wildcard ($devices.InstanceID) {

    #NZXT Smart Device V2
    #HID-Compliant Vendor-Defined Device
    "HID\VID_1E71&PID_2006&REV_0200" {

        Write-Host "NOTICE: Detected NZXT Smart Device V2. Installing NZXT CAM."

        $InstallLocation = "C:\Applications\Extra Software\NZXT CAM.exe"
        $Arguments = ""
        $ApplicationName = "NZXT CAM"
        Start-Install

    }

    #Corsair H100i
    #HID-Compliant Vendor-Defined Device
    "HID\VID_1B1C&PID_0C20\6&5281263&0&0000" {

        Write-Host "NOTICE: Detected Corsair H100i. Installing Corsair iCUE."

        WINGET Install --ID Corsair.iCUE.4 --Silent --Accept-Package-Agreements --Accept-Source-Agreements

        Copy-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Corsair\iCUE.lnk" -Destination "C:\Users\$ENV:Username\Desktop"
        
    }

    #Elgato HD60 Pro
    #Sound, Video, and Game Controllers
    "*VEN_12AB&DEV_0380&SUBSYS_00061CFA&REV_00*" {

        Write-Host "NOTICE: Detected Elgato HD60 Pro. Installing Elgato software."

        $InstallLocation = "C:\Applications\Extra Software\Elgato HD60Pro\4KCaptureUtility.msi"
        $Arguments = "/PASSIVE /NORESTART"
        $ApplicationName = "Elgato 4K Capture Utility"
        Start-Install

        $InstallLocation = "C:\Applications\Extra Software\Elgato HD60Pro\GameCaptureSetup.msi"
        $Arguments = "/PASSIVE /NORESTART"
        $ApplicationName = "Elgato Game Capture Utility"
        Start-Install

    }

    #Sound BlasterX AE-5 Plus
    #Sound, Video, and Game Controllers
    "*VEN_1102&DEV_0011&SUBSYS_1102019REV_1009*" {

        Write-Host "NOTICE: Detected Sound BlasterX AE-5 Plus. Installing Sound Blaster audio software."

        $InstallLocation = "C:\Applications\Extra Software\Sound BlasterX.exe"
        $Arguments = "/SILENT /NORESTART"
        $ApplicationName = "Sound BlasterX AE-5 Plus"
        Start-Install

    }

    #Wraith Prism
    #USB Composite Device
    "USB\VID_2516&PID_0051\7&*" {

        Write-Host "NOTICE: Detected Wraith Prism cooler. Installing Cooler Master RGB software."
        Copy-Item -Path 'C:\Applications\Extra Software\Wraith Prism' -Destination 'C:\Program Files (x86)\Wraith Prism' -Recurse
        Move-Item -Path "C:\Program Files (x86)\Wraith Prism\Wraith Prism.lnk" -Destination "C:\Users\$ENV:Username\Desktop"

    }
    
    #Unable to use the 'Default' variable. It gets triggered anytime one of the values being checked in
    #the switch statement are false. This means if the first device checked is not in the list, it goes
    #to default. Need to make something that checks if the switch statement did anything after it executes.
    <#Default {

        Write-Host "NOTICE: No RGB devices detected in the system. Proceeding with Windows install."
        Write-Host "Recorded system devices:"
        Write-Host "$devices"
        Write-Host "End of list."    
        Break

    }#>

}

#iRacing Installation
switch -Wildcard ($ENV:Computername) {

    #Uses the computers name to detect if iRacing software is needed or not
    "*-iRacing*" {

        Write-Host "NOTICE: Computer name includes iRacing. Will now install all required iRacing files."
        & 'C:\Applications\Extra Software\iRacing\Driver.exe' /S /v/qn
        & 'C:\Applications\Extra Software\iRacing\vc2012_redist_x64.exe' /install /passive /norestart
        & 'C:\Applications\Extra Software\iRacing\vc2012_redist_x86.exe' /install /passive /norestart
        & 'C:\Applications\Extra Software\iRacing\vc2013_redist_x64.exe' /install /passive /norestart
        & 'C:\Applications\Extra Software\iRacing\vc2013_redist_x86.exe' /install /passive /norestart
        & 'C:\Applications\Extra Software\iRacing\vc2015_redist_x64.exe' /install /passive /norestart
        & 'C:\Applications\Extra Software\iRacing\vc2015_redist_x86.exe' /install /passive /norestart
        & 'C:\Applications\Extra Software\iRacing\vc2017_redist_x64.exe' /install /passive /norestart
        & 'C:\Applications\Extra Software\iRacing\vc2017_redist_x86.exe' /install /passive /norestart
        Enable-WindowsOptionalFeature -NoRestart -Online -FeatureName "NetFx3"
        Copy-Item "C:\Applications\Extra Software\iRacing\EasyAntiCheat" -Destination "C:\Program Files (x86)"
        Copy-Item "C:\Applications\Extra Software\iRacing\iRacing" -Destination "C:\Program Files (x86)"
        Copy-Item "C:\Applications\Extra Software\iRacing\Shortcuts\*" -Destination "C:\Users\$ENV:Username\Desktop"
        Break

    }

    Default {
        
        Write-Host "NOTICE: This computer does not contain 'iRacing' in the name. Skipping software install."
        Break
    
    }

}

#Stops logging
Stop-Transcript
<#

.DESCRIPTION
Testing script for launching tests, performing System Prep, and QC

.AUTHOR
Ethan P. Schmidtke

.GITHUB


#>

Start-Transcript -Path "C:\TestingScript.txt" -IncludeInvocationHeader -Force

#Set our console properties
$host.UI.RawUI.ForegroundColor = "Green"
$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.WindowTitle = "Testing Script"

#Set our variables
#$ErrorActionPreference = "SilentlyContinue"
$applications = "C:\Applications"
$windowsEdition = (Get-WmiObject Win32_OperatingSystem).Caption
$motherboard = (Get-WmiObject Win32_BaseBoard).Manufacturer
$GPUs = [System.Collections.ArrayList]@(Get-PnpDevice -Class 'Display')
$t = 0
$f = 0

#List of functions available to the user    
function Stop-Tasks {
    
    #Kills all testing applications in the event they are still running
    Write-Host "Killing tasks" -InformationAction Ignore

    Get-Process -Name Prime95, FurMark, superposition, launcher, HWiNFO64, DCv2 -ErrorAction SilentlyContinue | Stop-Process -PassThru
    
}

function Start-Tests {
    
    Clear-Host

    Write-Host "Starting stress testing"

    Write-Host "Changing power settings to High Performance" -InformationAction Ignore
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg -x -monitor-TIMEOUT-ac 0

    Stop-Tasks

    Write-Host "Launching Prime95" -InformationAction Ignore
    Start-Process -FilePath "$applications\StressTest\Prime95\prime95.exe" -ArgumentList "-t" -WindowStyle "Minimized"

    $i = 0
    while ($i -le ($GPUs.Count - 1)) {
        
        switch -Wildcard ($GPUs[$i].FriendlyName) {
            
            "Intel(R) UHD*" {

                Write-Host "Intel integrated GPU detected, removing from array: $GPUs[$i].FriendlyName" -InformationAction Ignore
                $GPUs.RemoveAt($i)
                $i++

            }

            "AMD Radeon(TM)*" {

                Write-Host "AMD integrated GPU detected, removing from array: $GPUs[$i].FriendlyName" -InformationAction Ignore
                $GPUs.RemoveAt($i)
                $i++

            }

        }

        $i++

    }

    switch -Wildcard ($GPUs.InstanceID) {

        #NVIDIA Vendor ID
        "*VEN_10DE*" {

            #Launches Unigine Superposition if NVIDIA card is present
            Write-Host "Launching Superposition" -InformationAction Ignore
            Start-Process -FilePath "$applications\StressTest\Superposition\bin\superposition_cli.exe" -ArgumentList "-api directX -textures High -quality High -dof 1 -motion_blur 0 -fullscreen 2 -resolution 1920x1080 -sound 0 -mode Default -mode_duration 180 -iteration 1 -log_csv_step 60 -key GM036C393D6BI2O510O070560 -log_csv C:\Applications\StressTest\Superposition\result_pass1_medium.csv"
            $dedicatedGPU = "1"
            Break

        }

        #AMD Vendor ID
        "*VEN_1002*" {

            #Launches FurMark if an AMD card is present
            Write-Host "Launching Furmark with custom settings" -InformationAction Ignore
            Start-Process -FilePath "$applications\StressTest\FurMark\FurMark.exe" -ArgumentList "/width=1920, /height=1080, /nogui, /run_mode=2, /msaa=8, /log_temperature"
            $dedicatedGPU = "2"
            Break

        }

        Default {

            Write-Host "No dedicated GPU detected. Skipping GPU stress tests." -InformationAction Ignore
            $dedicatedGPU = "0"
            Break

        }

    }

    Write-Host "Launching HWiNFO64" -InformationAction Ignore
    Start-Process -FilePath "$applications\StressTest\HWiNFO64\HWiNFO64.EXE" -Wait

    Stop-Tasks

    switch ($dedicatedGPU) {
    
        "0" {
        
            Break
        
        }

        "1" {
        
            Import-Csv -Path "C:\Applications\StressTest\Superposition\result_pass1_medium.csv" -Delimiter "`t" | Format-Table "TEMPERATURE *"
        
        }

        "2" {
        
            Start-Process -FilePath "Notepad.exe" "$applications\StressTest\FurMark\furmark-gpu-monitoring.xml"
        
        }
    
    }

    Start-Process -FilePath "$applications\StressTest\Prime95\results.txt"

    switch (Get-Content -Path "$applications\StressTest\Prime95\results.txt" | %{$_ -match "expected"}) {
    
        "True" {

            $t++
            
        }

        "False" {
        
            $f++
        
        }
        
    }

    switch ($t) {
    
        "0" {
        
            Write-Host "Detected 0 Prime failures, passed."
            PAUSE
        
        }
        
        {$_ -gt 1 -lt 6} {
        
            Write-Host "Detected $_ Prime failures, passed."
            PAUSE

        }

        Default {
        
            Write-Host "Detected '$_' Prime failures, please resolve."
            PAUSE
        
        }
    
    }

    Get-ScheduledTask -TaskName "Start Tests" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$False -PassThru

    Get-Selection

}

function Start-SP {

    Clear-Host

    Write-Host "Starting Software Prep" -InformationAction Ignore

    Stop-Tasks

    #Clears out 'SoftwareDistribution' folder
    #Disables the Windows Update service (wuauserv) to do so
    Write-Host "Emptying 'SoftwareDistribution' folder" -InformationAction Ignore
    Set-Service -Name "wuauserv" -StartupType "Disabled"
    Stop-Service -Name "wuauserv" -Force
    Remove-Item -Path "$ENV:Windir\SoftwareDistribution" -Recurse -Force
    Set-Service -Name "wuauserv" -StartupType "Manual"
    Set-Service -Name "wuauserv" -Status "Running"

    Write-Host "Opening Device Manager and Disk Management" -InformationAction Ignore
    Start-Process "devmgmt.msc"
    Start-Process "diskmgmt.msc"

    Write-Host "Running 'Disk Cleanup'" -InformationAction Ignore
    Start-Process "cleanmgr.exe" -ArgumentList "/VERYLOWDISK, /D C"

    Write-Host "Having tester set Microsoft Edge homepage to Ironsidecomputers.com" -InformationAction Ignore
    Set-Clipboard -Value "http://ironsidecomputers.com/"
    Start-Process "msedge.exe"

    Write-Host "Removing OneDrive and Edge startup keys. They don't need to start with Windows" -InformationAction Ignore
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name �OneDrive'
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name �MicrosoftEdgeAutoLaunch_98769996E24836F99EC8617644423B4C'

    Write-Host "Removing Microsoft Edge link on desktop" -InformationAction Ignore
    Remove-Item -Path "$ENV:Homepath\Desktop\Microsoft Edge.lnk" -Force

    switch -Wildcard ($motherboard) {

        "*Intel*" {

            Write-Host "Skip opening 'Extra Software' and 'Pictures' folders. System is a laptop." -InformationAction Ignore
            Break

        }

        Default {

            Write-Host "Please install any necessary software and set the correct background"
            Write-Host "Opening 'Extra Software' and 'Pictures' folders for tester" -InformationAction Ignore
            Start-Process -FilePath "$applications\Extra Software"
            Start-Process -FilePath "$ENV:Homepath\Pictures"

        }

    }
    
    Get-Selection

}

function Start-QC {

    Clear-Host
    Set-Location "$applications\Script\OA3"

    switch -Wildcard ($windowsEdition) {
            
        "*10 Home*" {
            
            .\oa3tool.exe /assemble /configfile=".\10_Home.cfg"

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_). Likely finished sucessfully."
                    PAUSE
                
                }
                
                "-1073741517" {
                    
                    Write-Host "OA3 Tool exited with code ($_). Likely means the OA3 Home file needs an updated key source."
                    PAUSE

                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to generate key. Please consult Ethan."
                    PAUSE
                
                }
            
            }
        
        }

        "*10 Pro*" {

            .\oa3tool.exe /assemble /configfile=".\10_Pro.cfg"

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_). Likely finished sucessfully."
                    PAUSE
                
                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to generate key. Please consult Ethan."
                    PAUSE
                
                }

            }

        }

        "*11 Home*" {

            .\oa3tool.exe /assemble /configfile=".\11_Home.cfg"

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_). Likely finished sucessfully."
                    PAUSE
                
                }

                "-1073741517" {
                    
                    Write-Host "OA3 Tool exited with code ($_). Likely means the OA3 Home file needs an updated key source."
                    PAUSE

                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to generate key. Please consult Ethan."
                    PAUSE
                
                }

            }

        }

        "*11 Pro*" {

            .\oa3tool.exe /assemble /configfile=".\11_Pro.cfg"

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_) trying to generate key. Likely finished sucessfully."
                    PAUSE
                
                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to generate key. Please consult Ethan."
                    PAUSE
                
                }

            }

        }

        Default {

            Write-Host "The detected Windows edition was '$windowsEdition'. This does not match any known editions." -InformationAction Ignore
            EXIT 0

        }

    }

    switch -Wildcard ($motherboard) {

        "*Micro-Star*" {
            
            .\MSI\OA30W5E1.exe /A:C:\OA3.bin

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_). Likely finished sucessfully."
                    PAUSE
                
                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to inject key. Please consult Ethan."
                    PAUSE
                
                }
            
            }
        
        }

        "*ASUS*" {
            
            .\ASUS\SlpBuilder.exe /oa30:C:\OA3.bin

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_). Likely finished sucessfully."
                    PAUSE
                
                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to inject key. Please consult Ethan."
                    PAUSE
                
                }

            }
        
        }

        "*ASRock*" {

            .\ASRock\AFUWINx64.exe /A:C:\OA3.bin

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_). Likely finished sucessfully."
                    PAUSE
                
                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to inject key. Please consult Ethan."
                    PAUSE
                
                }

            }
        
        }

        "*Intel*" {
            
            .\Intel\iFlashVWin64.exe /A:C:\OA3.bin

            switch ($LastExitCode) {
                
                "0" {
                
                    Write-Host "OA3 Tool exitied with code ($_). Likely finished sucessfully."
                    PAUSE
                
                }

                Default {
                
                    Write-Host "OA3 Tool exited with unknown code ($_) trying to inject key. Please consult Ethan."
                    PAUSE
                
                }
            
            }

        }

        Default {

            Write-Host "Detected '$motherboard' as the system motherboard. This does not match our known list of MSI, ASUS, ASRock, or Intel NUC."
            PAUSE
            EXIT

        }

    }

    #This is meant to generate a report for MDOS, although this does not currently work.
    #.\oa3tool.exe report /configfile=C:\OA3.xml

    Write-Host
    Write-Host "[Y/y] - Activation succeeded, finish QC"
    Write-Host "[R/r] - Activation failed, retry"
    Write-Host
    $activation = Read-Host -Prompt "Did Windows activation work?"

    switch -Wildcard ($activation) {

        "Y" {

            Write-Host "Finalizing QC"
            Start-Sleep -Seconds 2

        }

        "R" {

            Write-Host "Attempting activation again"
            Start-Sleep -Seconds 2
            Start-QC

        }

        Default {

            Write-Host "Not sure what '$_' is supposed to mean. Please try again."
            Start-Sleep -Seconds 2
            Start-QC

        }

    }

    Write-Host "Clearing out File Explorer History" -InformationAction Ignore
    Remove-Item -Path "$ENV:Appdata\Microsoft\Windows\Recent\*" -Recurse -Force
    Remove-Item -Path "$ENV:Appdata\Microsoft\Windows\Recent\AutomatiSet-Locationestinations\*" -Recurse -Force
    Remove-Item -Path "$ENV:Appdata\Microsoft\Windows\Recent\CustomDestinations\*" -Recurse -Force

    Write-Host "Clearing out downloads and temp files" -InformationAction Ignore
    Remove-Item -Path "$ENV:Homepath\Downloads\*" -Recurse -Force
    Remove-Item -Path "$ENV:Temp\*" -Recurse -Force

    Write-Host "Changing Power Settings To Balanced" -InformationAction Ignore
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 
    powercfg -x -monitor-TIMEOUT-ac 10

    Write-Host "Removing transcript and renaming OA3 file" -InformationAction Ignore
    Rename-Item -Path "C:\OA3.xml" -NewName "WindowsKey.xml" -Force
    Remove-Item -Path "$ENV:Homepath\Desktop\Testing Launcher.lnk" -Force
    Remove-Item -Path "C:\OA3.bin" -Force
    Stop-Transcript
    Remove-Item -Path "C:\TestingScript.txt" -Force

    Write-Host "Removing Applications directory" -InformationAction Ignore
    Set-Location "C:\"
    Remove-Item -Path "$applications" -Recurse -Force
    EXIT

}

function Get-Selection {

    Clear-Host
    Write-Host "[1] Launch Tests"
    Write-Host "[2] Software Prep"
    Write-Host "[3] Quality Control"
    Write-Host
    $selection = Read-Host "Key in a # here, then press [Enter]"

    switch ($selection) {

        "1" {
    
            Start-Tests
    
        }
    
        "2" {
    
            Start-SP
    
        }
    
        "3" {
    
            Start-QC
    
        }
    
        Default {
    
            Write-Host "You think you can just press '$selection' and get away with it? Nah chief, try again."
            Start-Sleep -Seconds 2
            Get-Selection
    
        }
    
    }
    
}

if ($args -eq "1") {
    
    Start-Tests

}

Get-Selection
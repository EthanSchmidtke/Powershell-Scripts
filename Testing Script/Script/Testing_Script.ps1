<#

.DESCRIPTION
Testing script for launching tests, performing System Prep, and QC

.AUTHOR
Ethan P. Schmidtke

.GITHUB


#>

Start-Transcript -Path "C:\TestingScript.ps1.txt" -Force

#Set our console properties
$host.UI.RawUI.ForegroundColor = "Green"
$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.WindowTitle = "Testing Script"

#Set our variables
$applications = "C:\Applications"
$windowsEdition = (Get-WmiObject Win32_OperatingSystem).Caption
$motherboard = (Get-WmiObject Win32_BaseBoard).Manufacturer
$GPUs = [System.Collections.ArrayList]@(Get-PnpDevice -Class 'Display')

#List of functions available to the user
function Stop-Tasks {
    
    #Kiils all testing applications in the event they are still running
    Write-Debug "Killing tasks"
    Stop-Process -Name HWiNFO64.exe -Force
    Stop-Process -Name FurMark.exe -Force
    Stop-Process -Name superposition.exe -Force
    Stop-Process -Name launcher.exe -Force
    Stop-Process -Name Prime95.exe -Force
    
}

function Start-Tests {
    
    Clear-Host

    Write-Host "Starting stress testing"

    Stop-Tasks

    Write-Debug "Changing power settings to High Performance"
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg -x -monitor-TIMEOUT-ac 0

    Write-Debug "Launching Prime95"
    Start-Process -FilePath "$applications\Prime95\prime95.exe" -ArgumentList "-t" -WindowStyle "Minimized"

    $i = 0
    while ($i -le ($GPUs.Count - 1)) {
        
        switch -Wildcard ($GPUs.FriendlyName[$i]) {
            
            "Intel(R) UHD*" {

                Write-Debug "Intel integrated GPU detected (" $GPUs[$i] "). Removing from array."
                $GPUs.RemoveAt($i)
                $i++

            }

            "AMD Radeon(TM)*" {

                Write-Debug "AMD integrated GPU detected (" $GPUs[$i] "). Removing from array."
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
            Write-Debug "Launching Superposition"
            Start-Process -FilePath "$applications\Superposition\bin\superposition_cli.exe" -ArgumentList "-key GM036C393D6BI2O510O070560, -xml "$applications\Script\Superposition\Test_Routine.xml""

        }

        #AMD Vendor ID
        "*VEN_1002*" {

            #Launches FurMark if an AMD card is present
            Write-Debug "Launching Furmark with custom settings"
            Start-Process -FilePath "C:\Program Files (x86)\Geeks3D\Benchmarks\FurMark\FurMark.exe" /width=1920 /height=1080 /nogui /run_mode=2 /msaa=8

        }

        Default {

            Write-Host "The detected GPU, $GPUs, is not AMD nor NVIDIA. Please resolve."
            Read-Host -Prompt "Press [Enter] to exit"
            EXIT

        }

    }

    Write-Debug "Launching HWiNFO64"
    Start-Process -FilePath "$applications\HWiNFO64\HWiNFO64.EXE" -Wait

    Stop-Tasks
    Start-Process -FilePath "Notepad.exe" "C:\Benchmark\Results\result_pass1_medium.csv"
    Start-Process -FilePath "Notepad.exe" "$applications\Prime95\results.txt"

    Unregister-ScheduledTask -TaskName "Start Tests" -Confirm:$False

}

function Start-SP {

    Clear-Host

    Write-Host "Starting Software Prep"

    Stop-Tasks

    Write-Debug "Changing Power Settings To Balanced"
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e > NUL
    powercfg -x -monitor-TIMEOUT-ac 10 > NUL

    Write-Debug "Removing Prime95"
    Remove-Item /Q /S "$applications\Prime95"

    Write-Debug "Uninstalling HWiNFO64"
    Remove-Item /s /q "$applications\HWiNFO64"

    Write-Debug "Uninstalling Superposition"
    Start-Process -FilePath "$applications\Superposition\unins000.exe" -ArgumentList "/SILENT"
    Remove-Item /S /Q "C:\Benchmark"

    Write-Debug "Uninstalling FurMark"
    Start-Process -FilePath "$applications\FurMark\unins000.exe" -ArgumentList "/SILENT, /SUPPRESSMSGBOXES"

    Set-Location "C:\Windows\System32"

    Write-Debug "Opening Device Manager"
    Start-Process -FilePath ".\devmgmt.msc"

    Write-Debug "Opening Disk Management"
    Start-Process -FilePath ".\diskmgmt.msc"

    Write-Debug "Running 'Disk Cleanup'"
    Start-Process -FilePath ".\cleanmgr.exe" -ArgumentList "/VERYLOWDISK, /D C"

    Write-Host "Check that homepage is set to www.ironsidecomputers.com"
    Write-Debug "Having tester set Microsoft Edge homepage to Ironsidecomputers.com"
    Start-Process -FilePath "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

    Start-Sleep -Seconds 10
    Write-Debug "Removing Microsoft Edge link on desktop"
    Remove-Item -Path "$ENV:Homepath\Desktop\Microsoft Edge.lnk" -Force

    #Clears out 'SoftwareDistribution' folder
    #Disables the Windows Update service (wuauserv) to do so
    Write-Debug "Emptying 'SoftwareDistribution' folder"
    Set-Service -Name "wuauserv" -StartupType "Disabled"
    Stop-Service -Name "wuauserv" -Force
    Remove-Item -Path "$ENV:Windir\SoftwareDistribution" -Recurse -Force
    Set-Service -Name "wuauserv" -StartupType "Manual"
    Set-Service -Name "wuauserv" -Status "Running"

    Write-Debug "Opening 'Extra Software' and 'Pictures' folders for tester"
    Start-Process -FilePath "$applications\Extra Software"
    Start-Process -FilePath "$ENV:Homepath\Pictures" -Wait
    Write-Host "Please install any necessary software and set the correct background"

}

function Start-QC {

    Clear-Host
    Set-Location "$applications\Script\OA3"

    switch -Wildcard ($windowsEdition) {
            
        "*10 Home*" {
            
            .\oa3tool.exe /assemble /configfile=".\10_Home.cfg"
        
        }

        "*10 Pro*" {

            .\oa3tool.exe /assemble /configfile=".\10_Pro.cfg"

        }

        "*11 Home*" {

            .\oa3tool.exe /assemble /configfile=".\11_Home.cfg"

        }

        "*11 Pro*" {

            .\oa3tool.exe /assemble /configfile=".\11_Pro.cfg"

        }

        Default {

            Write-Debug "The detected Windows edition was '$windowsEdition'. This does not match any known editions."
            EXIT 0

        }

    }

    switch -Wildcard ($motherboard) {

        "*Micro-Star*" {
            
            .\MSI\OA30W5E1.exe /A:C:\OA3.bin
        
        }

        "*ASUS*" {
            
            .\ASUS\SlpBuilder.exe /oa30:C:\OA3.bin
        
        }

        "*ASRock*" {

            .\ASRock\AFUWINx64.exe /A:C:\OA3.bin
        
        }

        "*Intel*" {

            .\Intel\

        }

        Default {

            Write-Debug "Detected '$motherboard' as the system motherboard. This does not match our known list of MSI, ASUS, ASRock, or Intel NUC."
            EXIT

        }

    }

    #This is meant to generate a report for MDOS, although this does not currently work.
    #.\oa3tool.exe report /configfile=C:\OA3.xml

    Write-Host "[Y/y] - Activation succeeded, finish QC"
    Write-Host "[R/r] - Activation failed, retry"
    Write-Host
    $activation = Read-Host -Prompt "Did Windows activation work?"

    switch ($activation) {

        "Y" {

            Write-Host "Finalizing QC"
            Start-Sleep -Seconds 2

        }

        "N" {

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

    Write-Debug "Clearing out File Explorer History"
    Remove-Item -Path "$ENV:Appdata\Microsoft\Windows\Recent" -Recurse -Force
    Remove-Item -Path "$ENV:Appdata\Microsoft\Windows\Recent\AutomatiSet-Locationestinations" -Recurse -Force
    Remove-Item -Path "$ENV:Appdata\Microsoft\Windows\Recent\CustomDestinations" -Recurse -Force

    Write-Debug "Clearing out downloads and temp files"
    Remove-Item -Path "$ENV:Homepath\Downloads" -Recurse -Force
    Remove-Item -Path "$ENV:Temp" -Recurse -Force

    Write-Debug "Removing transcript and renaming OA3 file"
    Rename-Item -Path "C:\OA3.xml" -NewName "WindowsKey.xml" -Force
    Remove-Item -Path "$ENV:Homepath\Desktop\Testing Launcher.lnk" -Force
    Remove-Item -Path "C:\OA3.bin" -Force
    Stop-Transcript
    Remove-Item -Path "C:\TestingScript.ps1.txt" -Force

    Write-Debug "Removing Applications directory"
    Set-Location "C:\"
    Remove-Item -Path "$applications" -Recurse -Force

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

Get-Selection
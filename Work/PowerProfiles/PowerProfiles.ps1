#Location variable(s) formatting; loc*Location*
#Set our location variables for FurMark, HWiNFO, and Prime95
#FurMark normal install location: C:\Program Files (x86)\Geeks3D\Benchmarks\FurMark\FurMark.exe
$locFurMark = "C:\Users\$ENV:Username\Desktop\PowerProfiles\Programs\FurMark"
$locHWiNFO = "C:\Users\$ENV:Username\Desktop\PowerProfiles\Programs\HWiNFO64"
$locP95 = "C:\Users\$ENV:Username\Desktop\PowerProfiles\Programs\Prime95"

function Start-FurMark {

    Stop-Process -Name FurMark -Force
    Write-Host "Launching FurMark"
    Start-Process -FilePath .\FurMark.exe -ArgumentList "/nogui /width=1920 /height=1080 /msaa=8 /run_mode=2 /contest_mode=0" -WorkingDirectory $locFurMark

}

function Start-P95 {

    Stop-Process -Name Prime95 -Force
    Write-Host "Launching Prime95"
    Start-Process -FilePath .\prime95.exe -ArgumentList -t -WorkingDirectory $locP95 -WindowStyle Minimized
    
}

function Start-HWiNFO {

    switch (Test-Path -Path "C:\Users\$ENV:Username\Documents\$fileName.CSV") {

        "True" {
            
            Write-Host "Previous testing run detected, deleting"
            Remove-Item -Path "C:\Users\$ENV:Username\Documents\$fileName.CSV" -Force
        
        }

        "False" {
            
            Write-Host "No prior testing run detected, continuing"
        
        }

    }

    Start-Process -FilePath .\HWiNFO64.exe -WorkingDirectory $locHWiNFO
    Write-Host "Launching HWiNFO and waiting 5 minutes for heatsink to soak"
    Start-Sleep -Seconds 310

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}")
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 10
    [System.Windows.Forms.SendKeys]::SendWait("+{TAB}")
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("$fileName")
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}")
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 1

    Stop-Process -Name HWiNFO64 -Force

}

function Get-BatteryStatus {

#Source: https://powershell.one/wmi/root/cimv2/win32_battery

switch ((Get-WmiObject win32_battery).estimatedChargeRemaining -le "30") {

    "True" {
        
        Write-Host "Battery level at or below 30%, power saving will turn on at 20%. Please charge system and try again."
        Pause
        Get-Selection
    
    }

    "False" {
        
        Write-Host "Battery level above 30%, proceeding."
    
    }

}

switch -Wildcard (Get-CimInstance -ClassName Win32_Battery | Select-Object -Property BatteryStatus) {

    "*1*" {
        
        Write-Host "Battery status detected: Battery Power - System is running on DC"
        $batteryStatusCurrent = 1
    
    }

    "*2*" {
        
        Write-Host "Battery status detected: AC Power - System is running on AC"
        $batteryStatusCurrent = 0
    
    }

    "*3*" {
        
        Write-Host "Battery status detected: Fully Charged - System is running on DC"
        $batteryStatusCurrent = 1
    
    }

    "*4*" {
        
        Write-Host "Battery status detected: Low - System is running on DC"
        $batteryStatusCurrent = 1
    
    }

    "*5*" {
        
        Write-Host "Battery status detected: Critical - System is running on DC"
        $batteryStatusCurrent = 1
    
    }

    "*6*" {
        
        Write-Host "Battery status detected: Charging - System is running on AC"
        $batteryStatusCurrent = 1
    
    }

    "*7*" {
        
        Write-Host "Battery status detected: Charging and High - System is running on AC"
        $batteryStatusCurrent = 0
    
    }

    "*8*" {
        
        Write-Host "Battery status detected: Charging and Low - System is running on AC"
        $batteryStatusCurrent = 0
    
    }

    "*9*" {
        
        Write-Host "Battery status detected: Charging and Critical - System is running on AC"
        $batteryStatusCurrent = 0
    
    }

    "*11*" {
        
        Write-Host "Battery status detected: Partially Charged - System is running on DC(?)"
        $batteryStatusCurrent = 1
    
    }

    Default {
        
        Write-Host "Battery status detected: $_ - Charging status unknown"
        $batteryStatusCurrent = Read-Host -Prompt "Is the system on AC or DC? (0/1)"

        switch ($batteryStatusCurrent) {

            "0" {

                Write-Host "User inputted '0', system is on AC"
                Break

            }

            "1" {

                Write-Host "User inputted '1', system is on DC"
                Break

            }

            Default {

                Write-Host "User inputted '$_' - Please resolve"
                Pause
                Write-Host "Script exiting, please run again"
                Start-Sleep -Seconds 1
                EXIT

            }

        }
    
    }

}

switch ($batteryStatusDesired) {

    "$batteryStatusCurrent" {

        Write-Host "Battery status matches what is needed for tests. Continuing."
        Start-Sleep -Seconds 1
        Break

    }

    Default {

        Write-Host "Battery status does not match what is needed for testing. Please resolve."
        Pause
        Get-Selection

    }

}
    
}

function Get-PowerScheme {

    #Blanks the selection variable
    $selection = $null
    
    $powerSchemeCurrent = powercfg /getactivescheme

    if ($powerSchemeCurrent -like "*$powerSchemeDesired*") {
        
        Write-Host "Correct power plan currently set, continuing"

    } else {
        
        Write-Host "Windows power plans do not match. Current power plan is '$powerSchemeCurrent'"
        Write-Host "Automatically adjusting power plan to match"

        $powerSchemes = powercfg /l
        $count = $powerSchemes.Count - 1

        3..$count | ForEach-Object {

            switch -Wildcard ($powerSchemes[$_]) {

                "*$powerSchemeDesired*" {

                    Write-Host "Setting power scheme to:"$powerSchemes[$_]
                    $powerSchemeDesiredGUID = $powerSchemes[$_] -Replace ".*: " -Replace " .*"
                    powercfg /s $powerSchemeDesiredGUID
                    Break

                }

                Default {

                    if ($_ -ge $count) {

                        throw {

                            Write-Host "No available power schemes match what is desired:" $powerSchemeDesired
                            $selection = Read-Host -Prompt "Would you like to continue with the current power scheme or exit? (1/2)"

                            switch ($selection) {

                                "1" {

                                    Write-Host "Continuing tests with '$powerSchemeCurrent' as power profile"
                                    Start-Sleep -Seconds 2
                                    Break

                                }

                                "2" {

                                    Write-Host "Exiting"
                                    Start-Sleep -Seconds 1
                                    EXIT

                                }

                                Default {

                                    Write-Host "Invalid selection - Exiting"
                                    Start-Sleep -Seconds 1
                                    EXIT

                                }

                            }

                        }
                        
                    }

                }

            }

        }

    }

}

function Get-CSVData {

#Courtesy of https://stackoverflow.com/questions/18860760/dealing-with-duplicate-headers-in-csv-files-in-powershell
#Managing CSV Files in PowerShell is a pain in the ass

# Use System.IO.StreamReader to get the first line. Much faster than Get-Content.
$StreamReader = New-Object System.IO.StreamReader -Arg $csvTemp

# Parse the first line with whatever delimiter you expect. Trim + Remove Empty columns.
# Comment out the last part if you want to generate headers for those who are empty.
[array]$Headers = $StreamReader.ReadLine() -Split "," | % { "$_".Trim() } | ? { $_ }

# Close the StreamReader, as the file will stay locked.
$StreamReader.Close()

# For each Header column
For ($i=0; $i -lt $Headers.Count; $i++) {

    if ($i -eq 0) { Continue } #Skip first column.

    # If in any previous column, give it a generic header name
    if ($Headers[0..($i-1)] -contains $Headers[$i]) {
        $Headers[$i] = "Header$i"
    }
}

# Import CSV with the new headers 
$temp = Import-Csv $csvTemp -Header $Headers

$temp | Select-Object -Skip 1 -First 1 -Property "$property" | Format-Table

}

function Get-Selection {

    #Blanks the selection variable
    $selection = $null

    Clear-Host

    Write-Host "----------------------------------------"
    Write-Host "|                                      |"
    Write-Host "|    1. AC OOB            2. AC MAX    |"
    Write-Host "|    3. DC OOB            4. DC MAX    |"
    Write-Host "|                                      |"
    Write-Host "----------------------------------------"

    $selection = Read-Host -Prompt "Plus select a test to run"

    switch ($selection) {
        
        "1" {

            Write-Host "Beginning AC OOB tests, checking Windows Power Scheme and battery status"
            $batteryStatusDesired = 0
            $powerSchemeDesired = "Balanced"
            Start-Sleep -Seconds 1
            Get-BatteryStatus
            Get-PowerScheme

            Write-Host "Power scheme and battery status appear correct, beginning tests"
            $fileName = "AC-OOB-Prime95"
            Start-P95
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Start-Sleep -Seconds 10

            $fileName = "AC-OOB-FurMark"
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            $fileName = "AC-OOB-Both"
            Start-P95
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            Clear-Host

            Write-Host "Tests completed. Displaying results below."
            Write-Host ""

            Write-Host "Prime95:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\AC-OOB-Prime95.CSV"
            $property = "*CPU Package*"
            Get-CSVData

            Write-Host "FurMark:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\AC-OOB-FurMark.CSV"
            $property = "*GPU Power*", "*TGP Power*"
            Get-CSVData

            Write-Host "Both:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\AC-OOB-Both.CSV"
            $property = "*CPU Package Power*", "GPU Power*", "TGP Power*"
            Get-CSVData

            Read-Host -Prompt "Please press Enter to continue"

            Get-Selection

        }

        "2" {

            Write-Host "Beginning AC MAX tests, checking Windows Power Scheme and battery status"
            $batteryStatusDesired = 0
            $powerSchemeDesired = "High Performance"
            Start-Sleep -Seconds 1
            Get-BatteryStatus
            Get-PowerScheme

            Write-Host "Power scheme and battery status appear correct, beginning tests"
            $fileName = "AC-MAX-Prime95"
            Start-P95
            Start-Sleep -Seconds 5v
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Start-Sleep -Seconds 10

            $fileName = "AC-MAX-FurMark"
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            $fileName = "AC-MAX-Both"
            Start-P95
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            Clear-Host

            Write-Host "Tests completed. Displaying results below:"
            Write-Host ""

            Write-Host "Prime95:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\AC-MAX-Prime95.CSV"
            $property = "*CPU Package*"
            Get-CSVData

            Write-Host "FurMark:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\AC-MAX-FurMark.CSV"
            $property = "*GPU Power*", "*TGP Power*"
            Get-CSVData

            Write-Host "Both:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\AC-MAX-Both.CSV"
            $property = "*CPU Package Power*", "GPU Power*", "TGP Power*"
            Get-CSVData

            Read-Host -Prompt "Please press Enter to continue"

            Get-Selection

        }

        "3" {

            Write-Host "Beginning DC OOB tests, checking Windows Power Scheme and battery status"
            $batteryStatusDesired = 1
            $powerSchemeDesired = "Balanced"
            Start-Sleep -Seconds 1
            Get-BatteryStatus
            Get-PowerScheme

            Write-Host "Power scheme and battery status appear correct, beginning tests"
            $fileName = "DC-OOB-Prime95"
            Start-P95
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Start-Sleep -Seconds 10

            $fileName = "DC-OOB-FurMark"
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            $fileName = "DC-OOB-Both"
            Start-P95
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            Clear-Host

            Write-Host "Tests completed. Displaying results below:"
            Write-Host ""

            Write-Host "Prime95:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\DC-OOB-Prime95.CSV"
            $property = "*CPU Package*"
            Get-CSVData

            Write-Host "FurMark:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\DC-OOB-FurMark.CSV"
            $property = "*GPU Power*", "*TGP Power*"
            Get-CSVData

            Write-Host "Both:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\DC-OOB-Both.CSV"
            $property = "*CPU Package Power*", "GPU Power*", "TGP Power*"
            Get-CSVData

            Read-Host -Prompt "Please press Enter to continue"

            Get-Selection

        }

        "4" {

            Write-Host "Beginning DC MAX tests, checking Windows Power Scheme and battery status"
            $batteryStatusDesired = 1
            $powerSchemeDesired = "High Performance"
            Start-Sleep -Seconds 1
            Get-BatteryStatus
            Get-PowerScheme

            Write-Host "Power scheme and battery status appear correct, beginning tests"
            $fileName = "DC-MAX-Prime95"
            Start-P95
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Start-Sleep -Seconds 10

            $fileName = "DC-MAX-FurMark"
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            $fileName = "DC-MAX-Both"
            Start-P95
            Start-FurMark
            Start-Sleep -Seconds 5
            Start-HWiNFO
            Stop-Process -Name Prime95 -Force
            Stop-Process -Name FurMark -Force
            Start-Sleep -Seconds 10

            Clear-Host

            Write-Host "Tests completed. Displaying results below:"
            Write-Host ""

            Write-Host "Prime95:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\DC-MAX-Prime95.CSV"
            $property = "*CPU Package*"
            Get-CSVData

            Write-Host "FurMark:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\DC-MAX-FurMark.CSV"
            $property = "*GPU Power*", "*TGP Power*"
            Get-CSVData

            Write-Host "Both:"
            $csvTemp = "C:\Users\$ENV:Username\Documents\DC-MAX-Both.CSV"
            $property = "*CPU Package Power*", "GPU Power*", "TGP Power*"
            Get-CSVData

            Read-Host -Prompt "Please press Enter to continue"

            Get-Selection

        }

        Default {

            Write-Host "Invalid character ($_), please try again."
            Start-Sleep -Seconds 1
            Get-Selection

        }

    }

}

Get-Selection

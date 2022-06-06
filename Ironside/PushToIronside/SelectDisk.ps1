#-------------------------------------------------------------------------#

#Start the logging 
Start-Transcript -Path "C:\SelectDisk_Transcript.txt"
Write-Host "Logging to C:\SelectDisk_Transcript.txt"

#-------------------------------------------------------------------------#

[System.Collections.ArrayList]$disksAll = @(Get-PhysicalDisk | Select-Object DeviceID,FriendlyName,BusType,MediaType,@{n="Size";e={[math]::Round($_.Size/1GB,2)}})
$selected = 0

Write-Host "Currently detected drives:"
$disksAll | Format-Table

#Removes USB drives from array
$count = 0
$($disksAll.Clone()) | ForEach-Object {
        
    if ($_.BusType -eq "USB") {
        Write-Host "Removing disk" $disksAll[$count].FriendlyName "from array, it is a USB drive"
        $disksAll.RemoveAt($count)
    } else {
        $count++
    }

}

#Checks if the system contains 0 or 1 drive(s)
if ($disksAll.Count -lt 2) {

    switch ($disksAll.Count) {

        "0" {

            Write-Host "System contains no drives, please resolve and try again."
            EXIT 1

        }

        "1" {

            Write-Host "System contains 1 drive, selecting for install"
            $TSenv.Value("TargetDisk") = $disksAll.DeviceID
            $selected = 1
            Break

        }

    }

}

<#

Process:

NVMe
(x) If 1 NVMe is detected, pick for install and remove it from the master array
(x) If 2+ NVMe drives are detected, pick the smallest size and remove it from the master array

SSD (Assuming there are no NVMe drives)
(x) If 1 SSD is detected, pick for install and remove it from the master array
(x) If 2+ SSDs are detected, pick the smallest size and remove it from the master array

HDD (Assuming there are no SSDs)
(x) If 1 HDD is detected, pick for install and remove it from the master array
(x) If 2+ HDDs are detected, pick the smallest size and remove it from the master array

Future changes
(o) Functions - Convert frequently segments of code into functions to shorten overall script
as well as make it more efficient and easier to work on
(o) $_.RemoveAt([array]::indexof($array,WhatToLookFor)) - The indexof commandlet may be
able to shorten certain sections of code and make it less bulky

#>

#NVMe Drive Check
if ($selected -eq 0) {
    $count = 0
    :upHere switch (($disksAll.BusType -eq "NVMe").Count) {

        "1" {

            Write-Host "One NVMe drive detected. Selecting for install."
        
            $($disksAll.Clone()) | ForEach-Object {
                
                if ($_.BusType -eq "NVMe") {
                    $TSenv.Value("TargetDisk") = $disksAll[$count].DeviceID
                    Write-Host "Removing disk" $disksAll[$count].FriendlyName "from array - Selecting for install"
                    $disksAll.RemoveAt($count)
                    Break upHere
                } else {
                    $count++
                }
            
            }

        }

        Default {

            if (($disksAll.BusType -eq "NVMe").Count -ge 2) {

                [System.Collections.ArrayList]$disksTemp = @()
                $($disksAll.Clone()) | ForEach-Object {
                
                    if ($_.BusType -eq "NVMe") {
                        $disksTemp += $_[$count]
                        Write-Host "Removing disk" $disksAll[$count].FriendlyName "from main array and moving to temp array for size comparison"
                        $disksAll.RemoveAt($count)
                    }
                    $count++
                
                }

                $minimum = ($disksTemp | Measure-Object -Property Size -Minimum).Minimum
                $installDrive = $disksTemp | Where-Object {
                    
                    $_.Size -eq $minimum
                
                }

                $disksTemp.RemoveAt([array]::indexof($disksTemp,$installDrive))
                $TSenv.Value("TargetDisk") = $installDrive.DeviceID
                $selected = 1
                Write-Host "Selecting" $installDrive.FriendlyName "for install. This is the smallest NVMe available."

                Write-Host "Adding disks from temp array back to main array"
                Write-Host "Disks being added:" $disksTemp.FriendlyName
                $disksAll += $disksTemp

                Break upHere

            }

            Write-Host "No NVMe drives detected, checking for SSDs"
            Break upHere

        }

    }
}


#SSD Check
if ($selected -eq 0) {
    $count = 0
    :upHere switch ((($disksAll.BusType -eq "SATA") -and ($disksAll.MediaType -eq "SSD")).Count) {

        "1" {

            Write-Host "One SSD detected. Selecting for install."
        
            $($disksAll.Clone()) | ForEach-Object {
                
                if (($disksAll.BusType -eq "SATA") -and ($disksAll.MediaType -eq "SSD")) {
                    $TSenv.Value("TargetDisk") = $disksAll[$count].DeviceID
                    Write-Host "Removing disk" $disksAll[$count].FriendlyName "from array - Selecting for install"
                    $disksAll.RemoveAt($count)
                    Break upHere
                } else {
                    $count++
                }
            
            }

        }

        Default {

            if ((($disksAll.BusType -eq "SATA") -and ($disksAll.MediaType -eq "SSD")).Count -ge 2) {

                [System.Collections.ArrayList]$disksTemp = @()
                $($disksAll.Clone()) | ForEach-Object {
                
                    if (($_.BusType -eq "SATA") -and ($_.MediaType -eq "SSD")) {
                        $disksTemp += $_[$count]
                        Write-Host "Removing disk" $disksAll[$count].FriendlyName "from main array and moving to temp array for size comparison"
                        $disksAll.RemoveAt($count)
                    }
                    $count++
                
                }

                $minimum = ($disksTemp | Measure-Object -Property Size -Minimum).Minimum
                $installDrive = $disksTemp | Where-Object {
                    
                    $_.Size -eq $minimum
                
                }

                $disksTemp.RemoveAt([array]::indexof($disksTemp,$installDrive))
                $TSenv.Value("TargetDisk") = $installDrive.DeviceID
                $selected = 1
                Write-Host "Selecting" $installDrive.FriendlyName "for install. This is the smallest SSD available."

                Write-Host "Adding disks from temp array back to main array"
                Write-Host "Disks being added:" $disksTemp.FriendlyName
                $disksAll += $disksTemp

                Break upHere

            }

            Write-Host "No SSDs detected, checking for HDDs"
            Break upHere

        }

    }

}



#HDD Check
if ($selected -eq 0) {
    $count = 0
    :upHere switch ((($disksAll.BusType -eq "SATA") -and ($disksAll.MediaType -eq "HDD")).Count) {

        "1" {

            Write-Host "One HDD detected. Selecting for install."
        
            $($disksAll.Clone()) | ForEach-Object {
                
                if (($disksAll.BusType -eq "SATA") -and ($disksAll.MediaType -eq "HDD")) {
                    $TSenv.Value("TargetDisk") = $disksAll[$count].DeviceID
                    Write-Host "Removing disk" $disksAll[$count].FriendlyName "from array - Selecting for install"
                    $disksAll.RemoveAt($count)
                    Break upHere
                } else {
                    $count++
                }
            
            }

        }

        Default {

            if ((($disksAll.BusType -eq "SATA") -and ($disksAll.MediaType -eq "HDD")).Count -ge 2) {

                [System.Collections.ArrayList]$disksTemp = @()
                $($disksAll.Clone()) | ForEach-Object {
                
                    if (($_.BusType -eq "SATA") -and ($_.MediaType -eq "HDD")) {
                        $disksTemp += $_[$count]
                        Write-Host "Removing disk" $disksAll[$count].FriendlyName "from main array and moving to temp array for size comparison"
                        $disksAll.RemoveAt($count)
                    }
                    $count++
                
                }

                $minimum = ($disksTemp | Measure-Object -Property Size -Minimum).Minimum
                $installDrive = $disksTemp | Where-Object {
                    
                    $_.Size -eq $minimum
                
                }

                $disksTemp.RemoveAt([array]::indexof($disksTemp,$installDrive))
                $TSenv.Value("TargetDisk") = $installDrive.DeviceID
                $selected = 1
                Write-Host "Selecting" $installDrive.FriendlyName "for install. This is the smallest HDD available."

                Write-Host "Adding disks from temp array back to main array"
                Write-Host "Disks being added:" $disksTemp.FriendlyName
                $disksAll += $disksTemp

                Break upHere

            }

            Write-Host "No HDDs detected, not sure how we got here honestly"
            EXIT 1

        }

    }

}

#Formats/Partitions the remaining disk(s)
$count = 0
$disksAll | ForEach-Object {

Clear-Disk -Number $disksAll[$count].DeviceID -RemoveData -RemoveOEM
Initialize-Disk -Number $disksAll[$count].DeviceID -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "" -Confirm:$false
$count++

}

#Stops logging
Stop-Transcript
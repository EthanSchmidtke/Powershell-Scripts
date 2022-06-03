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
(o) If 2+ NVMe drives are detected, install to the smallest option and remove it from the master array

SSD (Assuming there are no NVMe drives)
(o) If 1 SSD is detected, pick for install and remove it from the master array
(o) If 2+ SSDs are detected, pick the smallest size or, if they are the same sizes, pick the one with the lowest DeviceID # and remove it from the master array

HDD (Assuming there are no SSDs)
(o) If 2+ HDDs are detected, pick the smallest size or, if they are the same sizes, pick the one with the lowest DeviceID # and remove it from the master array

$TSenv.Value("TargetDisk") = $disksAll.DeviceID

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
            Break

        }

    }
}


#SSD Check
if ($selected -eq 0) {
    $count = 0

}



#HDD Check
if ($selected -eq 0) {
    $count = 0

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
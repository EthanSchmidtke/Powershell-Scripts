<#-------------------------------------------------------------------------#

#Resources for script yoinked from http://www.vacuumbreather.com
#How to use arrays: https://mcpmag.com/articles/2019/04/10/managing-arrays-in-powershell.aspx

#-------------------------------------------------------------------------#>

#MDT Will create two different logs for this script upon deployment.
#Currently, I am not sure which one is more useful.

#Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")  
$logFile = "$logPath\$($myInvocation.MyCommand).log"

#Start the logging 
Start-Transcript $logFile
Write-Host "Logging to $logFile"

#-------------------------------------------------------------------------#

#$arrayDiskInfo - Gets the disk number, friendly name, device instance path, and disk size (Rounded)
#$arrayDiskType - Gets the disk type (HDD/SSD) with the friendly name
#$arrayMaster - Master list of all available disks. Contains size, type (HDD/SSD/NVMe), number, and friendly name. This starts blank and gets filled in later.

[System.Collections.ArrayList]$arrayDiskInfo = Get-Disk | Select-Object Number,FriendlyName,Path,@{n="Size";e={[math]::Round($_.Size/1GB,2)}}
[System.Collections.ArrayList]$arrayDiskType = Get-PhysicalDisk | Select-Object MediaType,FriendlyName
[System.Collections.ArrayList]$arrayMaster = @()
[System.Collections.ArrayList]$arrayNVMe = @()
[System.Collections.ArrayList]$arraySSD = @()
[System.Collections.ArrayList]$arrayHDD = @()

Function Convert-Type {
#Converts NVMe Media Type from 'SSD' to 'NVMe'
    
    $i = 0

    while ($i -le $arrayDiskInfo.Count) {
        if ($arrayDiskInfo.Path[$i] -like "*nvme*" -and $arrayDiskType.MediaType[$i] -eq "SSD") {
            $arrayDiskType[$i].MediaType = "NVMe"
        }
        $i++
    }
    
}

Function Find-USB {
#Checks if any available disks are USB drives, removing them from the array
    
    $i = 0

    While ($i -le $arrayDiskInfo.Capacity) {

        if ($arrayDiskInfo.Path[$i] -like "*usb*") {
            Write-Host "NOTICE: USB Drive detected, removing from array:" $arrayDiskInfo[$i]
            $arrayDiskInfo.RemoveAt($i)
            $arrayDiskType.RemoveAt($i)

        } elseif ($arrayDiskType.MediaType[$i] -eq "Unspecified") {
            Write-Host "NOTICE: USB Drive detected, removing from array:" $arrayDiskType[$i]
            $arrayDiskType.RemoveAt($i)
            
        } else {
            Write-Host "NOTICE: Non-USB Drive detected, skipping:" $arrayDiskInfo[$i]
            $i++

        }
    }
}

Function Set-MasterArrays {
#Creates the master arrays which contain all of the disks in the system

    $count = $arrayDiskInfo.Count - 1
    0..$count | ForEach-Object {

        $arrayData = @{}
        $arrayData.Number = $arrayDiskInfo[$_].Number
        $arrayData.Name = $arrayDiskInfo[$_].FriendlyName
        $arrayData.Type = $arrayDiskType[$_].MediaType
        $arrayData.Size = $arrayDiskInfo[$_].Size
    
        $objectName = New-Object PSobject -Property $arrayData

        switch ($objectName.Type) {
            
            "NVMe" {
                
                $arrayNVMe.Add($objectName)
                $arrayMaster.Add($objectName)

            }

            "SSD" {

                $arraySSD.Add($objectName)
                $arrayMaster.Add($objectName)

            }

            "HDD" {

                $arrayHDD.Add($objectName)
                $arrayMaster.Add($objectName)

            }

        }
            
    }
    
}

Function Select-Disk {
#Selects the disk to install Windows to and sets the variable for MDT

    if ($arrayNVMe.Count -gt "0") {
        
        switch ($arrayNVMe.Count) {
            
            "1" {
                
                Write-Host "NOTICE: One NVMe drive detected in system. Selecting for install."
                $TSenv.Value("TargetDisk") = $arrayNVMe.Number
                $arrayHDD.RemoveAt(0)

                Break

            }

            "2" {
                
                Write-Host "NOTICE: Two NVMe drives detected in system. Comparing size."
                
                if ($arrayNVMe[0].Size -gt $arrayNVMe[1].Size) {
                    
                    Write-Host "NOTICE: ($arrayNVMe[0]) is the larger NVMe drive. Installing Windows to drive ($arrayNVMe[1])."
                    $TSenv.Value("TargetDisk") = $arrayNVMe[1].Number
                    $arrayHDD.RemoveAt(1)

                } elseif ($arrayNVMe[1].Size -gt $arrayNVMe[0].Size) {
                    
                    Write-Host "NOTICE: ($arrayNVMe[1]) is the larger NVMe drive. Installing Windows to drive ($arrayNVMe[0])."
                    $TSenv.Value("TargetDisk") = $arrayNVMe[0].Number
                    $arrayHDD.RemoveAt(0)
                    
                } elseif ($arrayNVMe[0].Size -eq $arrayNVMe[1].Size) {
                    
                    Write-Host "NOTICE: ($arrayNVMe[0]) and ($arrayNVMe[1]) appear to be the same size. Installing to ($arrayNVMe[0])."
                    $TSenv.Value("TargetDisk") = $arrayNVMe[0].Number
                    $arrayHDD.RemoveAt(0)

                } else {
                    
                    Write-Host "NOTICE: Neither NVMe drive is larger than the other nor are they the same size. Not sure where to go from here."
                    EXIT 0

                }

                Break

            }

            "3" {

                Write-Host "LOL, you think this can handle more than 2 NVMe drives? Ridiculous."
                EXIT 0

            }

        }

    } elseif ($arraySSD.Count -gt "0") {
        
        switch ($arraySSD.Count) {
            
            "1" {
                
                Write-Host "NOTICE: One SSD detected in system. Selecting for install."
                $TSenv.Value("TargetDisk") = $arraySSD.Number
                $arrayHDD.RemoveAt(0)

                Break

            }

            "2" {
                
                Write-Host "NOTICE: Two SSDs detected in system. Comparing size."
                
                if ($arraySSD[0].Size -gt $arraySSD[1].Size) {
                    
                    Write-Host "NOTICE: ($arraySSD[0]) is the larger SSD. Installing Windows to drive ($arraySSD[1])."
                    $TSenv.Value("TargetDisk") = $arraySSD[1].Number
                    $arrayHDD.RemoveAt(1)

                } elseif ($arraySSD[1].Size -gt $arraySSD[0].Size) {
                    
                    Write-Host "NOTICE: ($arraySSD[1]) is the larger SSD. Installing Windows to drive ($arraySSD[0])."
                    $TSenv.Value("TargetDisk") = $arraySSD[0].Number
                    $arrayHDD.RemoveAt(0)
                    
                } elseif ($arraySSD[0].Size -eq $arraySSD[1].Size) {
                    
                    Write-Host "NOTICE: ($arraySSD[0]) and ($arraySSD[1]) appear to be the same size. Installing to ($arraySSD[0])."
                    $TSenv.Value("TargetDisk") = $arraySSD[0].Number
                    $arrayHDD.RemoveAt(0)

                } else {
                    
                    Write-Host "NOTICE: Neither SSD is larger than the other nor are they the same size. Not sure where to go from here."
                    EXIT 0

                }

                Break

            }

            "3" {

                Write-Host "LOL, you think this can handle more than 2 SSDs? Ridiculous."
                EXIT 0

            }

        }

    } elseif ($arrayHDD.Count -gt "0") {
        
        switch ($arrayHDD.Count) {
            
            "1" {
                
                Write-Host "NOTICE: One HDD detected in system. Selecting for install."
                $TSenv.Value("TargetDisk") = $arrayHDD.Number
                $arrayHDD.RemoveAt(0)

                Break

            }

            "2" {
                
                Write-Host "NOTICE: Two HDDs detected in system. Comparing size."
                
                if ($arrayHDD[0].Size -gt $arrayHDD[1].Size) {
                    
                    Write-Host "NOTICE: ($arrayHDD[0]) is the larger HDD. Installing Windows to drive ($arrayHDD[1])."
                    $TSenv.Value("TargetDisk") = $arrayHDD[1].Number
                    $arrayHDD.RemoveAt(1)

                } elseif ($arrayHDD[1].Size -gt $arrayHDD[0].Size) {
                    
                    Write-Host "NOTICE: ($arrayHDD[1]) is the larger HDD. Installing Windows to drive ($arrayHDD[0])."
                    $TSenv.Value("TargetDisk") = $arrayHDD[0].Number
                    $arrayHDD.RemoveAt(0)
                    
                } elseif ($arrayHDD[0].Size -eq $arrayHDD[1].Size) {
                    
                    Write-Host "NOTICE: ($arrayHDD[0]) and ($arrayHDD[1]) appear to be the same size. Installing to ($arrayHDD[0])."
                    $TSenv.Value("TargetDisk") = $arrayHDD[0].Number
                    $arrayHDD.RemoveAt(0)

                } else {
                    
                    Write-Host "NOTICE: Neither HDD is larger than the other nor are they the same size. Not sure where to go from here."
                    EXIT 0

                }

                Break

            }

            "3" {

                Write-Host "LOL, you think this can handle more than 2 HDDs? Ridiculous."
                EXIT 0

            }

        }

    } else {

        Write-Host "NOTICE: No disks are detected in the master arrays apparently. Go get Ethan."
        EXIT 0

    }
    
}

Function Format-Disks {
#Formats the remaining disks and gives them empty names

    if ($arrayNVMe.Count -gt "0") {

        $count = $arrayNVMe.Count - 1
        0..$count | ForEach-Object {

            Clear-Disk -Number $arrayNVMe[$_].Number -RemoveData -RemoveOEM
            Initialize-Disk -Number $arrayNVMe[$_].Number -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "" -Confirm:$false

        }
            
    }

    if ($arraySSD.Count -gt "0") {

        $count = $arraySSD.Count - 1
        0..$count | ForEach-Object {

            Clear-Disk -Number $arraySSD[$_].Number -RemoveData -RemoveOEM
            Initialize-Disk -Number $arraySSD[$_].Number -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "" -Confirm:$false
        
        }

    }

    if ($arrayHDD.Count -gt "0") {
        
        $count = $arraySSD.Count - 1
        0..$count | ForEach-Object {

            Clear-Disk -Number $arrayHDD[$_].Number -RemoveData -RemoveOEM
            Initialize-Disk -Number $arrayHDD[$_].Number -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "" -Confirm:$false
        
        }

    }

}

Convert-Type

Find-USB

Set-MasterArrays

Select-Disk

Format-Disks

#Stops logging
Stop-Transcript
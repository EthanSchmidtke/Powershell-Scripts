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

function Convert-Type {
#Converts NVMe Media Type from 'SSD' to 'NVMe'
    
    $i = 0

    while ($i -le $arrayDiskInfo.Count) {
        if ($arrayDiskInfo.Path[$i] -like "*nvme*" -and $arrayDiskType.MediaType[$i] -eq "SSD") {
            $arrayDiskType[$i].MediaType = "NVMe"
        }
        $i++
    }
    
}

function Find-USB {
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

function Set-MasterArray {
#Creates the master array which contains all of the disks in the system

    $i = 0
    $count = $arrayDiskInfo.Count - 1
    
    0..$count | ForEach-Object {
    
        $arrayData = @{}
        $arrayData.Number = $arrayDiskInfo[$i].Number
        $arrayData.Name = $arrayDiskInfo[$i].FriendlyName
        $arrayData.Type = $arrayDiskType[$i].MediaType
        $arrayData.Size = $arrayDiskInfo[$i].Size
    
        $Objectname = New-Object PSobject -Property $arrayData
    
        $arrayMaster.Add($Objectname)
    
        $i++
    }

}

function Select-Disk {
#Selects the disk to install Windows to and sets the variable for MDT

    $totalNVMe = ($arrayMaster.Type -eq "NVMe").Count
    Write-Host "Detected ($totalNVMe) NVMe drives."

    if ($totalNVMe -gt 0) {
        
    }

    $totalSSD = ($arrayMaster.Type -eq "SSD").Count
    Write-Host "Detected ($totalSSD) SSDs."

    $totalHDD = ($arrayMaster.Type -eq "HDD").Count
    Write-Host "Detected ($totalHDD) HDDs."



    $arrayMaster.Type -eq "SSD" | ForEach-Object {

        Write-Host $_

    }

    $TSenv.Value("TargetDisk") = switch ($arrayMaster.MediaType) {
        "NVMe" {$arrayMaster.Number}
        Default {}
    }
    
}

$arrayMaster -eq 0
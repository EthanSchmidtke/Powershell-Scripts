#Get-ChassisType function is used to determine if the system is a desktop or laptop so
#the correct actions are taken for activating Windows.
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
    
    switch($chassisType) {
        "1" {Write-Host "NOTICE: Chassis type 'Other' detected"; $Global:chassisType = "Other"; Break}
        "2" {Write-Host "NOTICE: Chassis type 'Unknown' detected"; $Global:chassisType = "Unknown"; Break}
        "3" {Write-Host "NOTICE: Chassis type 'Desktop' detected"; $Global:chassisType = "Desktop"; Break}
        "4" {Write-Host "NOTICE: Chassis type 'Low Profile Desktop' detected"; $Global:chassisType = "Low Profile Desktop"; Break}
        "5" {Write-Host "NOTICE: Chassis type 'Pizza Box' detected"; $Global:chassisType = "Pizza Box"; Break}
        "6" {Write-Host "NOTICE: Chassis type 'Mini Tower' detected"; $Global:chassisType = "Mini Tower"; Break}
        "7" {Write-Host "NOTICE: Chassis type 'Tower' detected"; $Global:chassisType = "Tower"; Break}
        "8" {Write-Host "NOTICE: Chassis type 'Portable' detected"; $Global:chassisType = "Portable"; Break}
        "9" {Write-Host "NOTICE: Chassis type 'Laptop' detected"; $Global:chassisType = "Laptop"; Break}
        "10" {Write-Host "NOTICE: Chassis type 'Notebook' detected"; $Global:chassisType = "Notebook"; Break}
        "11" {Write-Host "NOTICE: Chassis type 'Hand Held' detected"; $Global:chassisType = "Hand Held"; Break}
        "12" {Write-Host "NOTICE: Chassis type 'Docking Station' detected"; $Global:chassisType = "Docking Station"; Break}
        "13" {Write-Host "NOTICE: Chassis type 'All in One' detected"; $Global:chassisType = "All in One"; Break}
        "14" {Write-Host "NOTICE: Chassis type 'Sub Notebook' detected"; $Global:chassisType = "Sub Notebook"; Break}
        "15" {Write-Host "NOTICE: Chassis type 'Space-Saving' detected"; $Global:chassisType = "Space-Saving"; Break}
        "16" {Write-Host "NOTICE: Chassis type 'Lunch Box' detected"; $Global:chassisType = "Lunch Box"; Break}
        "17" {Write-Host "NOTICE: Chassis type 'Main System Chassis' detected"; $Global:chassisType = "Main System Chassis"; Break}
        "18" {Write-Host "NOTICE: Chassis type 'Expansion Chassis' detected"; $Global:chassisType = "Expansion Chassis"; Break}
        "19" {Write-Host "NOTICE: Chassis type 'SubChassis' detected"; $Global:chassisType = "SubChassis"; Break}
        "20" {Write-Host "NOTICE: Chassis type 'Bus Expansion Chassis' detected"; $Global:chassisType = "Bus Expansion Chassis"; Break}
        "21" {Write-Host "NOTICE: Chassis type 'Peripheral Chassis' detected"; $Global:chassisType = "Peripheral Chassis"; Break}
        "22" {Write-Host "NOTICE: Chassis type 'Storage Chassis' detected"; $Global:chassisType = "Storage Chassis"; Break}
        "23" {Write-Host "NOTICE: Chassis type 'Rack Mount Chassis' detected"; $Global:chassisType = "Rack Mount Chassis"; Break}
        "24" {Write-Host "NOTICE: Chassis type 'Sealed-Case PC' detected"; $Global:chassisType = "Sealed-Case PC"; Break}
        "30" {Write-Host "NOTICE: Chassis type 'Tablet' detected"; $Global:chassisType = "Tablet"; Break}
        "31" {Write-Host "NOTICE: Chassis type 'Convertible' detected"; $Global:chassisType = "Convertible"; Break}
        "32" {Write-Host "NOTICE: Chassis type 'Detachable' detected"; $Global:chassisType = "Detachable"; Break}
    }

}

#Runs the function Get-ChassisType and determines if the OA3 tool should be used or not.
Get-ChassisType
switch ($chassisType) {
    "Desktop" {Write-Host "NOTICE: System is a desktop, activating with OA3 tool"; $i = "1"; Break}
    "Other" {Write-Host "NOTICE: System is a desktop, activating with OA3 tool"; $i = "1"; Break}
    "Laptop" {Write-Host "NOTICE: System is a laptop, getting key"; $i = "0"; Break}
    "Unknown" {Write-Host "NOTICE: System is a laptop, getting key"; $i = "0"; Break}
    Default {
        Write-Error "What the McFuck is chassis type " $chassisType
        PAUSE
        EXIT 0
    }
}

#Sets the $Edition variable to the current 'Edition' of Windows installed to the local system
#so we know whether to get a key for Home or Pro.
$Edition = (Get-WmiObject win32_operatingsystem).Caption
Write-Host "NOTICE: Windows edition $Edition detected"

#Checks the detected chassis type and either generates a OA3.xml file (Laptop) before exiting
#or gathers the motherboard model before proceeding with injection (Desktop).
#1 = Desktop, 0 = Laptop
switch ($i) {
    "1" {
        #Sets the $Mobo variable to the current motherboard installed in the system. This is done
        #so we know whether to use the MSI, ASUS, or ASRock injection tool.
        #The $Mobo2 variable is used for ASUS as some of their boards do not show up in the first.
        $Mobo = Get-WmiObject -Class Win32_ComputerSystem | Select Manufacturer
        $Mobo2 = Get-WmiObject -Class Win32_BaseBoard | Select Manufacturer
        Write-Host "NOTICE: Detected $Mobo and $Mobo2 as the reported system motherboard"
        Break
    }
    "0" {
        #This checks what 'Edition' of Windows is installed and calls MDOS
        #for the respective key using the specified Config file.
        switch -Wildcard ($Edition) {
            "*10 Home*" {.\oa3tool.exe /assemble /configfile=".\OA3_Home_10.cfg"; EXIT}
            "*10 Pro*" {.\oa3tool.exe /assemble /configfile=".\OA3_Pro_10.cfg"; EXIT}
            "*11 Home*" {.\oa3tool.exe /assemble /configfile=".\OA3_Home_11.cfg"; EXIT}
            "*11 Pro*" {.\oa3tool.exe /assemble /configfile=".\OA3_Pro_11.cfg"; EXIT}
            Default {
                Write-Error "No Windows edition detected. Go get Ethan and fix your shit."
                EXIT 0
            }
        }
    }
}

#This checks what 'Edition' of Windows is installed and calls MDOS
#for the respective key using the specified Config file.
switch -Wildcard ($Edition) {
    "*10 Home*" {.\oa3tool.exe /assemble /configfile=".\OA3_Home_10.cfg"; Break}
    "*10 Pro*" {.\oa3tool.exe /assemble /configfile=".\OA3_Pro_10.cfg"; Break}
    "*11 Home*" {.\oa3tool.exe /assemble /configfile=".\OA3_Home_11.cfg"; Break}
    "*11 Pro*" {.\oa3tool.exe /assemble /configfile=".\OA3_Pro_11.cfg"; Break}
    Default {
        Write-Error "No Windows edition detected. Go get Ethan and fix your shit."
        PAUSE
        EXIT 0
    }
}

#This checks what manufacturer the motherboard is and, utilizing their injection tool, injects
#the previously generated Windows key.
switch -Wildcard ($Mobo,$Mobo2) {
    "*Micro-Star*" {.\MSI\OA30W5E1.exe /A:C:\OA3.bin; PAUSE; Break}
    "*ASUS*" {.\ASUS\SlpBuilder.exe /oa30:C:\OA3.bin; PAUSE; Break}
    "*ASRock*" {.\ASRock\AFUWINx64.exe /A:C:\OA3.bin; PAUSE; Break}
    Default {
        Write-Error "Detected motherboard is not ASUS, ASRock, or MSI."
        Write-Error "Variable 1: " $Mobo
        Write-Error "Variable 2: " $Mobo2
        PAUSE
        EXIT 0
    }
}

#This is meant to generate a report for MDOS, although this does not currently work.
#.\oa3tool.exe report /configfile=C:\OA3.xml

EXIT
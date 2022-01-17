#May not be needed
#Import-Module .\ZTIUtility.psm1
#Resources for script yoinked from http://www.vacuumbreather.com

#Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")  
$logFile = "$logPath\$($myInvocation.MyCommand).log"
$disks = @()

#http://ramblingcookiemonster.github.io/Join-Object/
Function Join-Object
 {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine = $true)]
        [object[]] $Left,

        # List to join with $Left
        [Parameter(Mandatory=$true)]
        [object[]] $Right,

        [Parameter(Mandatory = $true)]
        [string] $LeftJoinProperty,

        [Parameter(Mandatory = $true)]
        [string] $RightJoinProperty,

        [object[]]$LeftProperties = '*',

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [object[]]$RightProperties = '*',

        [validateset( 'AllInLeft', 'OnlyIfInBoth', 'AllInBoth', 'AllInRight')]
        [Parameter(Mandatory=$false)]
        [string]$Type = 'AllInLeft',

        [string]$Prefix,
        [string]$Suffix
    )
    Begin
    {
        function AddItemProperties($item, $properties, $hash)
        {
            if ($null -eq $item)
            {
                return
            }

            foreach($property in $properties)
            {
                $propertyHash = $property -as [hashtable]
                if($null -ne $propertyHash)
                {
                    $hashName = $propertyHash["name"] -as [string]         
                    $expression = $propertyHash["expression"] -as [scriptblock]

                    $expressionValue = $expression.Invoke($item)[0]
            
                    $hash[$hashName] = $expressionValue
                }
                else
                {
                    foreach($itemProperty in $item.psobject.Properties)
                    {
                        if ($itemProperty.Name -like $property)
                        {
                            $hash[$itemProperty.Name] = $itemProperty.Value
                        }
                    }
                }
            }
        }

        function TranslateProperties
        {
            [cmdletbinding()]
            param(
                [object[]]$Properties,
                [psobject]$RealObject,
                [string]$Side)

            foreach($Prop in $Properties)
            {
                $propertyHash = $Prop -as [hashtable]
                if($null -ne $propertyHash)
                {
                    $hashName = $propertyHash["name"] -as [string]         
                    $expression = $propertyHash["expression"] -as [scriptblock]

                    $ScriptString = $expression.tostring()
                    if($ScriptString -notmatch 'param\(')
                    {
                        Write-Verbose "Property '$HashName'`: Adding param(`$_) to scriptblock '$ScriptString'"
                        $Expression = [ScriptBlock]::Create("param(`$_)`n $ScriptString")
                    }
                
                    $Output = @{Name =$HashName; Expression = $Expression }
                    Write-Verbose "Found $Side property hash with name $($Output.Name), expression:`n$($Output.Expression | out-string)"
                    $Output
                }
                else
                {
                    foreach($ThisProp in $RealObject.psobject.Properties)
                    {
                        if ($ThisProp.Name -like $Prop)
                        {
                            Write-Verbose "Found $Side property '$($ThisProp.Name)'"
                            $ThisProp.Name
                        }
                    }
                }
            }
        }

        function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties)
        {
            $properties = @{}

            AddItemProperties $leftItem $leftProperties $properties
            AddItemProperties $rightItem $rightProperties $properties

            New-Object psobject -Property $properties
        }

        #Translate variations on calculated properties.  Doing this once shouldn't affect perf too much.
        foreach($Prop in @($LeftProperties + $RightProperties))
        {
            if($Prop -as [hashtable])
            {
                foreach($variation in ('n','label','l'))
                {
                    if(-not $Prop.ContainsKey('Name') )
                    {
                        if($Prop.ContainsKey($variation) )
                        {
                            $Prop.Add('Name',$Prop[$Variation])
                        }
                    }
                }
                if(-not $Prop.ContainsKey('Name') -or $Prop['Name'] -like $null )
                {
                    Throw "Property is missing a name`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                }


                if(-not $Prop.ContainsKey('Expression') )
                {
                    if($Prop.ContainsKey('E') )
                    {
                        $Prop.Add('Expression',$Prop['E'])
                    }
                }
            
                if(-not $Prop.ContainsKey('Expression') -or $Prop['Expression'] -like $null )
                {
                    Throw "Property is missing an expression`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                }
            }        
        }

        $leftHash = @{}
        $rightHash = @{}

        # Hashtable keys can't be null; we'll use any old object reference as a placeholder if needed.
        $nullKey = New-Object psobject
        
        $bound = $PSBoundParameters.keys -contains "InputObject"
        if(-not $bound)
        {
            [System.Collections.ArrayList]$LeftData = @()
        }
    }
    Process
    {
        #We pull all the data for comparison later, no streaming
        if($bound)
        {
            $LeftData = $Left
        }
        Else
        {
            foreach($Object in $Left)
            {
                [void]$LeftData.add($Object)
            }
        }
    }
    End
    {
        foreach ($item in $Right)
        {
            $key = $item.$RightJoinProperty

            if ($null -eq $key)
            {
                $key = $nullKey
            }

            $bucket = $rightHash[$key]

            if ($null -eq $bucket)
            {
                $bucket = New-Object System.Collections.ArrayList
                $rightHash.Add($key, $bucket)
            }

            $null = $bucket.Add($item)
        }

        foreach ($item in $LeftData)
        {
            $key = $item.$LeftJoinProperty

            if ($null -eq $key)
            {
                $key = $nullKey
            }

            $bucket = $leftHash[$key]

            if ($null -eq $bucket)
            {
                $bucket = New-Object System.Collections.ArrayList
                $leftHash.Add($key, $bucket)
            }

            $null = $bucket.Add($item)
        }

        $LeftProperties = TranslateProperties -Properties $LeftProperties -Side 'Left' -RealObject $LeftData[0]
        $RightProperties = TranslateProperties -Properties $RightProperties -Side 'Right' -RealObject $Right[0]

        #I prefer ordered output. Left properties first.
        [string[]]$AllProps = $LeftProperties

        #Handle prefixes, suffixes, and building AllProps with Name only
        $RightProperties = foreach($RightProp in $RightProperties)
        {
            if(-not ($RightProp -as [Hashtable]))
            {
                Write-Verbose "Transforming property $RightProp to $Prefix$RightProp$Suffix"
                @{
                    Name="$Prefix$RightProp$Suffix"
                    Expression=[scriptblock]::create("param(`$_) `$_.'$RightProp'")
                }
                $AllProps += "$Prefix$RightProp$Suffix"
            }
            else
            {
                Write-Verbose "Skipping transformation of calculated property with name $($RightProp.Name), expression:`n$($RightProp.Expression | out-string)"
                $AllProps += [string]$RightProp["Name"]
                $RightProp
            }
        }

        $AllProps = $AllProps | Select -Unique

        Write-Verbose "Combined set of properties: $($AllProps -join ', ')"

        foreach ( $entry in $leftHash.GetEnumerator() )
        {
            $key = $entry.Key
            $leftBucket = $entry.Value

            $rightBucket = $rightHash[$key]

            if ($null -eq $rightBucket)
            {
                if ($Type -eq 'AllInLeft' -or $Type -eq 'AllInBoth')
                {
                    foreach ($leftItem in $leftBucket)
                    {
                        WriteJoinObjectOutput $leftItem $null $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
            else
            {
                foreach ($leftItem in $leftBucket)
                {
                    foreach ($rightItem in $rightBucket)
                    {
                        WriteJoinObjectOutput $leftItem $rightItem $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
        }

        if ($Type -eq 'AllInRight' -or $Type -eq 'AllInBoth')
        {
            foreach ($entry in $rightHash.GetEnumerator())
            {
                $key = $entry.Key
                $rightBucket = $entry.Value

                $leftBucket = $leftHash[$key]

                if ($null -eq $leftBucket)
                {
                    foreach ($rightItem in $rightBucket)
                    {
                        WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
        }
    }
}

#Start the logging 
Start-Transcript $logFile
Write-Host "Logging to $logFile"
 
#Start Main Code Here

#$disksorder is used to get the disk number, hardware ID, and display name
#$physicaldisks is used to get the disk 'type' for each disk (SSD/HDD)
#$disks is used to join both disksorder and physicaldisks into one variable
#$TotalDisks is used to track how many disks are installed in the system
#$TotalSSDs is used to track how many drives show up with the media type SSD
#$TotalHDDs is used to track how many drives show up with the media type HDD

$disksorder = Get-Disk | Select-Object Number,FriendlyName,Path
$physicaldisks = Get-PhysicalDisk | Select-Object FriendlyName,MediaType,@{n="Size";e={[math]::Round($_.Size/1GB,2)}}
$disks = Join-Object -Left $disksorder -Right $physicaldisks -LeftJoinProperty FriendlyName -RightJoinProperty FriendlyName
$TotalDisks = 0
Write-Host "Detected $TotalDisks Disks - Write"
Write-Warning "Detected $TotalDisks Disks - Warning"
Write-Error "Detected $TotalDisks Disks - Error"
$TotalSSDs = 0
$TotalHDDs = 0

#This loop checks how many total disks are detected by the system and updates the variable $TotalDisks to match
ForEach($disk in $disks) {
        $TotalDisks++
        Write-Warning "Detected $TotalDisks Disk(s)"   
    }

#This checks if there is more than one drive in the system. If there is, the script continues. If there is not, the script
#assumes there is only one drive plugged in, sets the variable, and proceeds with Windows install.
if($TotalDisks -lt "2") {
    $TSenv.Value("TargetDisk") = $disk.Number
    Write-Warning "System only has one drive. $disk"
    }

#This loop checks if any of the installed drives are NVMe drives. If one is detected, the script will set the variable
#and exit the script. If one is not detected nothing happens and the script continues.
ForEach($disk in $disks) {       
        if($disk.Path -like "*nvme*") {
            #Have this set the install drive variable in MDT - We shouldn't need
            #to worry about multiple M.2 drives being installed as we do not
            #allow that on the site.
            Write-Warning "NVMe drive detected: $disk"
            $TSenv.Value("TargetDisk") = $disk.Number
            Exit 0
            }
    }

#This loop checks what MediaType the installed disks report and increases the associated variable for the 'total'.
ForEach($disk in $disks) {
        if($disk.MediaType -eq "SSD") {
            Write-Warning "SSD drive detected: $disk"
            $TotalSSDs++
            }
        
        elseif($disk.MediaType -eq "HDD") {
            Write-Warning "HDD drive detected: $disk"
            $TotalHDDs++
            }
    }

#This loop checks if one or more SSD is installed.
if($TotalSSDs -gt "0") {
    if($TotalSSDs -eq "1") {
        ForEach($disk in $disks) {
            if($disk.MediaType -eq "SSD") {
                #Have this set the variable for installation to the sole SSD. If there is only one SSD in the system,
                #it can safely be the installation drive as NVMe drives were ruled out earlier.
                $SSD = $disk.Number
                $TSenv.Value("TargetDisk") = $SSD
                Write-Warning "One SSD detected, setting variable to $SSD"
                Exit 0
            }
        }
    }
    if($TotalSSDs -eq "2") {
        ForEach($disk in $disks) {
            if($disk.MediaType -eq "SSD" -and $disk.Number -eq "0") {
                $Size0 = $disk.Size
                Write-Warning "SSD Detected, disk number 0"                   
                }
            if($disk.MediaType -eq "SSD" -and $disk.Number -eq "1") {
                $Size1 = $disk.Size
                Write-Warning "SSD Detected, disk number 1"                    
                }
            if($disk.MediaType -eq "SSD" -and $disk.Number -eq "2") {
                $Size2 = $disk.Size
                Write-Warning "SSD Detected, disk number 2"                    
                }
            }
         if($Size0 -gt "100") {
            if($Size1 -gt "100" ) {
                if($Size0 -ge $Size1) {
                    #Set installation variable to disk 1 as it is smaller than disk 0
                    $TSenv.Value("TargetDisk") = 1
                    Write-Warning "SSD 1 Detected to be smaller than SSD 0. Setting variable."
                    Exit 0
                    }
                else {
                    #Set installation variable to disk 0 as it is smaller than disk 1
                    $TSenv.Value("TargetDisk") = 0
                    Write-Warning "SSD 0 Detected to be smaller than SSD 1. Setting variable."
                    Exit 0
                    }
                }
            elseif($Size2 -gt "100") {
                if($Size0 -ge $Size2) {
                    #Set installation variable to disk 2 as it is smaller than disk 0
                    $TSenv.Value("TargetDisk") = 2
                    Write-Warning "SSD 2 Detected to be smaller than SSD 0. Setting variable."
                    Exit 0
                    }
                else {
                    #Set installation variable to disk 0 as it is smaller than disk 2
                    $TSenv.Value("TargetDisk") = 0
                    Write-Warning "SSD 0 Detected to be smaller than SSD 2. Setting variable."
                    Exit 0
                }
            }
        }
         if($Size1 -gt "100") {
            if($Size2 -gt "100" ) {
                if($Size1 -ge $Size2) {
                    #Set installation variable to disk 2 as it is smaller than disk 1
                    $TSenv.Value("TargetDisk") = 2
                    Write-Warning "SSD 2 Detected to be smaller than SSD 1. Setting variable."
                    Exit 0
                    }
                else {
                    #Set installation variable to disk 1 as it is smaller than disk 2
                    $TSenv.Value("TargetDisk") = 1
                    Write-Warning "SSD 1 Detected to be smaller than SSD 2. Setting variable."
                    Exit 0
                    }
                }
            }
        }
}

#This loop checks if one or more HDD is installed.
if($TotalHDDs -gt "0") {
    if($TotalHDDs -eq "1") {
        ForEach($disk in $disks) {
            if($disk.MediaType -eq "HDD") {
                #Have this set the variable for installation to the sole HDD. If there is only one HDD in the system,
                #it can safely be the installation drive as NVMe drives were ruled out earlier.
                $HDD = $disk.Number
                $TSenv.Value("TargetDisk") = $HDD
                Write-Warning "One HDD detected, setting variable to $HDD"
                Exit 0
            }
        }
    }
    if($TotalHDDs -eq "2") {
        ForEach($disk in $disks) {
            if($disk.MediaType -eq "HDD" -and $disk.Number -eq "0") {
                $Size0 = $disk.Size
                Write-Warning "HDD Detected, disk number 0"                   
                }
            if($disk.MediaType -eq "HDD" -and $disk.Number -eq "1") {
                $Size1 = $disk.Size
                Write-Warning "HDD Detected, disk number 1"                    
                }
            if($disk.MediaType -eq "HDD" -and $disk.Number -eq "2") {
                $Size2 = $disk.Size
                Write-Warning "HDD Detected, disk number 2"                    
                }
            }
         if($Size0 -gt "100") {
            if($Size1 -gt "100" ) {
                if($Size0 -ge $Size1) {
                    #Set installation variable to disk 1 as it is smaller than disk 0
                    $TSenv.Value("TargetDisk") = 1
                    Write-Warning "HDD 1 Detected to be smaller than HDD 0. Setting variable."
                    Exit 0
                    }
                else {
                    #Set installation variable to disk 0 as it is smaller than disk 1
                    $TSenv.Value("TargetDisk") = 0
                    Write-Warning "HDD 0 Detected to be smaller than HDD 1. Setting variable."
                    Exit 0
                    }
                }
            elseif($Size2 -gt "100") {
                if($Size0 -ge $Size2) {
                    #Set installation variable to disk 2 as it is smaller than disk 0
                    $TSenv.Value("TargetDisk") = 2
                    Write-Warning "HDD 2 Detected to be smaller than HDD 0. Setting variable."
                    Exit 0
                    }
                else {
                    #Set installation variable to disk 0 as it is smaller than disk 2
                    $TSenv.Value("TargetDisk") = 0
                    Write-Warning "HDD 0 Detected to be smaller than HDD 2. Setting variable."
                    Exit 0
                }
            }
        }
         if($Size1 -gt "100") {
            if($Size2 -gt "100" ) {
                if($Size1 -ge $Size2) {
                    #Set installation variable to disk 2 as it is smaller than disk 1
                    $TSenv.Value("TargetDisk") = 2
                    Write-Warning "HDD 2 Detected to be smaller than HDD 1. Setting variable."
                    Exit 0
                    }
                else {
                    #Set installation variable to disk 1 as it is smaller than disk 2
                    $TSenv.Value("TargetDisk") = 1
                    Write-Warning "HDD 1 Detected to be smaller than HDD 2. Setting variable."
                    Exit 0
                    }
                }
            }
        }
}
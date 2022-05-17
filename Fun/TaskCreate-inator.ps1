#This is a recreation of my Nuke_Prompt.bat script

$i = 0

Start-Process powershell.exe "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
while ($i -lt 100000) {

    Write-Host "Ope"
    $i++

}
EXIT
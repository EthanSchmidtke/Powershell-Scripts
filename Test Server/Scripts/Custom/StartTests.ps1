$Action = New-ScheduledTaskAction -Execute "C:\Applications\Script\TST.bat"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $Action -TaskName "Start Tests" -Trigger $Trigger -Force
$PicsDir = "D:\ProgramData\Microsoft\User Account Pictures\"
Remove-Item "$PicsDir\guest.png" -Force
Remove-Item "$PicsDir\user.png" -Force
Remove-Item "$PicsDir\user-32.png" -Force
Remove-Item "$PicsDir\user-40.png" -Force
Remove-Item "$PicsDir\user-48.png" -Force
Remove-Item "$PicsDir\user-192.png" -Force
$ServerDir = "\\SERVER-2\Test$\Scripts\Custom\Default_Profile\Pictures"
$Dest = "D:\ProgramData\Microsoft\User Account Pictures\"
Copy-Item "$ServerDir\guest.png" $Dest -Force
Copy-Item "$ServerDir\user.png" $Dest -Force
Copy-Item "$ServerDir\user-32.png" $Dest -Force
Copy-Item "$ServerDir\user-40.png" $Dest -Force
Copy-Item "$ServerDir\user-48.png" $Dest -Force
Copy-Item "$ServerDir\user-192.png" $Dest -Force
@ECHO OFF
@TITLE Network Check Startup Script

ECHO Checking that scripts are in the correct locations

if not exist "C:\NetworkCheck.ps1" (

    move /y "%~dp0\NetworkCheck.ps1" "C:\"

)

if not "%~dp0"=="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" (

    move /y "%~f0" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

)

ECHO Starting NetworkCheck.ps1
PowerShell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\NetworkCheck.ps1""' -Verb RunAs}"
TIMEOUT 5 > NUL
EXIT
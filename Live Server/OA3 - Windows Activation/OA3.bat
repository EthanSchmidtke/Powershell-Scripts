@ECHO OFF
@TITLE OA3Tool

:: NOTE: This script REQUIRES the OA3.ps1 script to be run BEFORE this
:: to gather the variables

SET Directory=C:\Applications\OA3

:: This checks what 'Edition' of Windows is installed and calls MDOS
:: for the respective key using the specified Config file.

IF %1==Home_10 (
	ECHO Windows 10 Home
        %Directory%\oa3tool.exe /assemble /configfile="%Directory%\OA3_Home_10.cfg"
	)

IF %1==Pro_10 (
	ECHO Windows 10 Pro
	%Directory%\oa3tool.exe /assemble /configfile="%Directory%\OA3_Pro_10.cfg"
	)

IF %1==Home_11 (
	ECHO Windows 11 Home
        %Directory%\oa3tool.exe /assemble /configfile="%Directory%\OA3_Home_11.cfg"
	)

IF %1==Pro_11 (
	ECHO Windows 11 Pro
	%Directory%\oa3tool.exe /assemble /configfile="%Directory%\OA3_Pro_11.cfg"
	)

:: This checks what motherboard is installed using the variable set
:: by the .ps1 script. All manufacturers have their own injection software
:: for some reason.

IF %2==MSI (
	%Directory%\MSI\OA30W5E1.exe /A:C:\OA3.bin
	)

IF %2==ASUS (
	%Directory%\ASUS\SlpBuilder.exe /oa30:C:\OA3.bin
	)

IF %2==ASRock (
	%Directory%\ASRock\AFUWINx64.exe /A:C:\OA3.bin
	)

PAUSE
%Directory%\oa3tool.exe /report /configfile=C:\OA3.xml

EXIT
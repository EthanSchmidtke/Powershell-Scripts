@ECHO OFF
@TITLE Get A Windows Key
MODE CON: cols=65 lines=9

CD /D "%~dp0"

ECHO -------------------------------------
ECHO     Please make a selection below
ECHO -------------------------------------
ECHO.
ECHO -----------------------------------------------------------------
ECHO       1. Windows 10 Home                 2. Windows 10 Pro
ECHO       3. Windows 11 Home                 4. Windows 11 Pro
ECHO -----------------------------------------------------------------

CHOICE /C:1234 > NUL

IF ERRORLEVEL 4 GOTO:11Pro
IF ERRORLEVEL 3 GOTO:11Home
IF ERRORLEVEL 2 GOTO:10Pro
IF ERRORLEVEL 1 GOTO:10Home

:10Home
oa3tool.exe /assemble /configfile="OA3_Home_10.cfg"
EXIT

:10Pro
oa3tool.exe /assemble /configfile="OA3_Pro_10.cfg"
EXIT

:11Home
oa3tool.exe /assemble /configfile="OA3_Home_11.cfg"
EXIT

:11Pro
oa3tool.exe /assemble /configfile="OA3_Pro_11.cfg"
EXIT
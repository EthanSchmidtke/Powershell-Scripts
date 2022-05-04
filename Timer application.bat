::Generic timer application because I CAN'T be defeated

@ECHO OFF
@TITLE Timer

:STARTUP
CLS
SET /P setup=Largest value? Days/Hours/Minutes/Seconds (d/h/m/s): 
SET "var="&for /f "delims=dhms" %%i in ("%setup%") do set var=%%i
IF Defined var (

    ECHO You must enter a supported value! - d/h/m/s
    TIMEOUT 3 > NUL
    GOTO:STARTUP

)
GOTO:%setup%

:D
:d
SET /P days=Days: 
SET "var="&for /f "delims=0123456789" %%i in ("%days%") do set var=%%i
IF Defined var (
    
    ECHO You have to set a number!
    ECHO.
    TIMEOUT 1 > NUL
    GOTO:D

)

:H
:h
SET /P hours=Hours: 
SET "var="&for /f "delims=0123456789" %%i in ("%hours%") do set var=%%i
if defined var (
    
    ECHO You have to set a number!
    ECHO.
    TIMEOUT 1 > NUL
    GOTO:H

)

:M
:m
SET /P minutes=Minutes: 
SET "var="&for /f "delims=0123456789" %%i in ("%minutes%") do set var=%%i
if defined var (
    
    ECHO You have to set a number!
    ECHO.
    TIMEOUT 1 > NUL
    GOTO:M

)

:S
:s
SET /P seconds=Seconds: 
SET "var="&for /f "delims=0123456789" %%i in ("%seconds%") do set var=%%i
if defined var (
    
    ECHO You have to set a number!
    ECHO.
    TIMEOUT 1 > NUL
    GOTO:S

) ELSE (

    IF NOT Defined days (
        SET days=0
    )
    IF NOT Defined hours (
        SET /A hours=0
    )
    IF NOT Defined minutes (
        SET minutes=0
    )
    IF NOT Defined seconds (
        SET seconds=0
    )
    GOTO:INITIALIZE

)

:INITIALIZE
SET /A timeLeft=%days%*86400+%hours%*3600+%minutes%*60+%seconds%
SET /A totalTime=%timeLeft%

:TIMER
IF %timeLeft% EQU -1 (

    CLS
    ECHO Time is up!
    PAUSE

) ELSE (

    CLS
    SET /A timeLeft=%timeLeft% - 1
    @TITLE Timer - Time Remaining: %timeLeft% - Total Time: %totalTime%
    ECHO Total Time: %totalTime%
    ECHO Time Left: %timeLeft%
    ECHO Press Ctrl+C to stop
    TIMEOUT /T 1 /NOBREAK > NUL
    GOTO:TIMER

)

PAUSE
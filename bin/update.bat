@echo off

REM Identify the process ID (PID) of the running instance of your application
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq blissful_backdrop.exe" /fo table /nh') do (
    set PID=%%i
)

REM Terminate the application if it's running
if defined PID (
    echo Closing the running instance of the application...
    taskkill /pid %PID% /f
    timeout /t 2 /nobreak >nul 2>&1
)

REM Launch the updated executable
echo Launching the updated executable...
start "" "%~1"

exit
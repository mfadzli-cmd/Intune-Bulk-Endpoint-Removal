@echo off
cls
echo ===============================================================================
echo                Intune Bulk Endpoint Purge Utility Bootstrapper
echo ===============================================================================
echo.
echo Checking for Administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Administrator privileges confirmed.
) else (
    echo.
    echo ERROR: Administrative privileges are required.
    echo Please right-click Launch-Utility.cmd and select "Run as Administrator".
    echo.
    pause
    exit /b 1
)

echo.
echo Launching the PowerShell utility...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0Intune-Bulk-Endpoint-Purge-Utility.ps1"

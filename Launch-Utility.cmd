@echo off
cls
echo ===============================================================================
echo                Intune Bulk Endpoint Purge Utility Bootstrapper
echo ===============================================================================
echo.
echo Launching the PowerShell utility...
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Intune-Bulk-Endpoint-Purge-Utility.ps1"

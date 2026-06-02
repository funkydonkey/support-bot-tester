@echo off
REM Windows wrapper — double-click or run from cmd.exe.
REM Launches the PowerShell setup with execution policy bypassed for this run only.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
pause

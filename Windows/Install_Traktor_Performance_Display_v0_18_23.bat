@echo off
setlocal
cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo This installer needs Administrator rights.
  echo Right-click this BAT and choose "Run as administrator".
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-TraktorPerformanceDisplay.ps1"
echo.
pause

@echo off
title GitHub Achievement Helper
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitHub-Achievement-Helper.ps1"
if errorlevel 1 pause

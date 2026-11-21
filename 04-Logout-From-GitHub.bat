@echo off
title 04-Logout-From-GitHub
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp004-Logout-From-GitHub.ps1"
if errorlevel 1 pause

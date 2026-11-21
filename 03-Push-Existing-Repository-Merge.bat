@echo off
title 03-Push-Existing-Repository-Merge
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp003-Push-Existing-Repository-Merge.ps1"
if errorlevel 1 pause

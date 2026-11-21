@echo off
title 02-Create-New-Public-Repository
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp002-Create-New-Public-Repository.ps1"
if errorlevel 1 pause

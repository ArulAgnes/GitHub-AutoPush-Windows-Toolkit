@echo off
title 01-Login-to-My-GitHub
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp001-Login-to-My-GitHub.ps1"
if errorlevel 1 pause

@echo off
title Push Solar Repository to GitHub
echo ========================================================
echo Pushing Solar Project to GitHub...
echo Target: https://github.com/vishnu564-eb/solar.git
echo ========================================================

cd /d "%~dp0"
"C:\Users\VISHN\git\cmd\git.exe" push -u origin main

pause

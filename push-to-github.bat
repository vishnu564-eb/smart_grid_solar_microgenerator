@echo off
title Push smart_grid_solar_microgenerator to GitHub
echo ========================================================
echo Pushing Smart Grid Solar Microgenerator to GitHub...
echo Repository: https://github.com/vishnu564-eb/smart_grid_solar_microgenerator.git
echo ========================================================

set PATH=C:\Users\VISHN\git\cmd;C:\Users\VISHN\git\mingw64\bin;C:\Users\VISHN\git\usr\bin;%PATH%

cd /d "%~dp0"
"C:\Users\VISHN\git\cmd\git.exe" push -u origin main

pause

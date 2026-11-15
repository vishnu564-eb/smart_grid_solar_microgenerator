@echo off
title Netze BW Solar Microgenerator Full-Stack Portal
echo ========================================================
echo Starting Solar Microgenerator Spring Boot Backend & UI...
echo Web Dashboard: http://localhost:8085
echo Camunda Zeebe Target: localhost:26500
echo ========================================================

set JAVA_HOME=C:\Users\VISHN\openjdk-21
set PATH=%JAVA_HOME%\bin;C:\Users\VISHN\apache-maven-3.9.9\bin;%PATH%

cd /d "%~dp0springboot"
call "C:\Users\VISHN\apache-maven-3.9.9\bin\mvn.cmd" spring-boot:run

pause

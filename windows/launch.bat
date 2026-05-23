@echo off
title Edible Planet: Cosmic Feast
echo ============================================
echo   EDIBLE PLANET: COSMIC FEAST
echo   Cooperative 2D Game
echo ============================================
echo.

REM Check if Godot is available
where godot >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Launching with Godot...
    godot --path "%~dp0"
    goto :end
)

REM Check for exported exe
if exist "%~dp0EdiblePlanet.exe" (
    echo Launching exported build...
    start "" "%~dp0EdiblePlanet.exe"
    goto :end
)

REM No Godot, no exe — tell user what to do
echo.
echo Godot not found! You need Godot 4.x to run this project.
echo.
echo QUICK SETUP:
echo   1. Download Godot from: https://godotengine.org/download/windows/
echo   2. Extract the .exe to any folder
echo   3. Run: godot4.exe --path "%~dp0"
echo.
echo OR: Open Godot, click "Import", select this folder's project.godot
echo.
pause

:end

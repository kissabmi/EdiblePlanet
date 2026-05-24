@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Edible Planet - Windows 11 Auto Install

set "INSTALL_ROOT=C:\Program Files (x86)\Games"
set "GAME_DIR=%INSTALL_ROOT%\EdiblePlanet"
set "GAME_HTML=%GAME_DIR%\edible_planet.html"
set "LAUNCHER=%GAME_DIR%\Play Edible Planet.bat"
set "RAW_URL=https://raw.githubusercontent.com/kissabmi/EdiblePlanet/master/web/edible_planet.html"

echo.
echo ======================================================
echo   EDIBLE PLANET - FULL AUTO INSTALL FOR WINDOWS 11
echo ======================================================
echo.

net session >nul 2>nul
if not "%ERRORLEVEL%"=="0" (
  echo [ERROR] Запусти этот файл от имени администратора.
  echo Правый клик по .bat - Run as administrator / Запуск от имени администратора.
  pause
  exit /b 1
)

echo [1/5] Создаю папку: %GAME_DIR%
if not exist "%INSTALL_ROOT%" mkdir "%INSTALL_ROOT%"
if not exist "%GAME_DIR%" mkdir "%GAME_DIR%"
if not exist "%GAME_DIR%" (
  echo [ERROR] Не смог создать папку установки.
  pause
  exit /b 1
)

echo [2/5] Скачиваю игру одним файлом...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%RAW_URL%' -OutFile '%GAME_HTML%' -UseBasicParsing"
if not exist "%GAME_HTML%" (
  echo [ERROR] Не скачался файл игры. Проверь интернет и запусти снова.
  pause
  exit /b 1
)

echo [3/5] Создаю запускатор...
(
  echo @echo off
  echo chcp 65001 ^>nul
  echo start "" "%GAME_HTML%"
) > "%LAUNCHER%"

echo [4/5] Создаю ярлык на рабочем столе...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Edible Planet.lnk'); $s.TargetPath='%LAUNCHER%'; $s.WorkingDirectory='%GAME_DIR%'; $s.Description='Edible Planet: Cosmic Feast'; $s.Save()"

echo [5/5] Запускаю игру...
start "" "%GAME_HTML%"

echo.
echo ======================================================
echo   ГОТОВО
echo   Игра установлена сюда:
echo   %GAME_DIR%
echo.
echo   На рабочем столе создан ярлык: Edible Planet
echo   В следующий раз запускай его.
echo ======================================================
echo.
pause

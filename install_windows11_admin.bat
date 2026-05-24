@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Edible Planet - Windows 11 Auto Install

set "INSTALL_ROOT=C:\Program Files (x86)\Games"
set "GAME_DIR=%INSTALL_ROOT%\EdiblePlanet"
set "GAME_EXE=%GAME_DIR%\EdiblePlanet.exe"
set "LAUNCHER=%GAME_DIR%\Play Edible Planet.bat"
set "EXE_URL=https://github.com/kissabmi/EdiblePlanet/releases/latest/download/EdiblePlanet.exe"

echo.
echo ======================================================
echo   EDIBLE PLANET - WINDOWS 11 AUTO INSTALL
echo ======================================================
echo.

net session >nul 2>nul
if not "%ERRORLEVEL%"=="0" (
  echo [ERROR] Запусти этот файл от имени администратора.
  echo Правый клик по .bat - Запуск от имени администратора.
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

echo [2/5] Скачиваю настоящий Windows .exe...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%EXE_URL%' -OutFile '%GAME_EXE%' -UseBasicParsing"
if not exist "%GAME_EXE%" (
  echo [ERROR] Не скачался EdiblePlanet.exe.
  echo Проверь интернет. Если релиз ещё собирается, подожди 2 минуты и запусти снова.
  pause
  exit /b 1
)

for %%A in ("%GAME_EXE%") do set "SIZE=%%~zA"
if %SIZE% LSS 100000 (
  echo [ERROR] Скачался не exe, а страница ошибки GitHub. Подожди релиз и запусти снова.
  del "%GAME_EXE%" >nul 2>nul
  pause
  exit /b 1
)

echo [3/5] Создаю запускатор...
(
  echo @echo off
  echo chcp 65001 ^>nul
  echo cd /d "%GAME_DIR%"
  echo start "" "%GAME_EXE%"
) > "%LAUNCHER%"

echo [4/5] Создаю ярлык на рабочем столе...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Edible Planet.lnk'); $s.TargetPath='%GAME_EXE%'; $s.WorkingDirectory='%GAME_DIR%'; $s.Description='Edible Planet: Cosmic Feast'; $s.Save()"

echo [5/5] Запускаю игру...
start "" "%GAME_EXE%"

echo.
echo ======================================================
echo   ГОТОВО
echo   Игра установлена сюда:
echo   %GAME_DIR%
echo.
echo   На рабочем столе ярлык: Edible Planet
echo ======================================================
echo.
pause

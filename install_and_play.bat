@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Edible Planet — One-Click Install & Play

REM ═══════════════════════════════════════════════════════
REM  Этот скрипт делает ВСЁ сам:
REM  1. Проверяет/ставит Git
REM  2. Клонирует игру с GitHub
REM  3. Скачивает Godot
REM  4. Экспортирует standalone .exe
REM  5. Запускает игру
REM  Запускать от имени администратора!
REM ═══════════════════════════════════════════════════════

echo.
echo  ███████╗██████╗ ███████╗███████╗██████╗ 
echo  ██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗
echo  █████╗  ██████╔╝█████╗  █████╗  ██║  ██║
echo  ██╔══╝  ██╔══██╗██╔══╝  ██╔══╝  ██║  ██║
echo  ██║     ██║  ██║███████╗███████╗██████╔╝
echo  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝
echo  PLANET: COSMIC FEAST — One-Click Install
echo.

REM ─── Где всё ставить ───
set "INSTALL_DIR=%USERPROFILE%\EdiblePlanet"
set "GODOT_VER=4.3"
set "GODOT_URL=https://github.com/godotengine/godot/releases/download/%GODOT_VER%-stable/Godot_v%GODOT_VER%-stable_win64.exe.zip"
set "REPO_URL=https://github.com/kissabmi/EdiblePlanet.git"

echo [*] Install directory: %INSTALL_DIR%
echo.

REM ═══════ 1. ПРОВЕРЯЕМ GIT ═══════
echo [1/5] Checking Git...

where git >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo       [OK] Git found.
    goto :git_done
)

echo       Git not found. Installing...

REM Проверяем winget (есть на Win11)
where winget >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo       Installing Git via winget...
    winget install --id Git.Git --accept-package-agreements --accept-source-agreements --silent
    if !ERRORLEVEL! EQU 0 (
        echo       [OK] Git installed.
        REM Обновляем PATH
        set "PATH=%PATH%;C:\Program Files\Git\cmd"
        goto :git_done
    )
)

REM winget не сработал — пробуем скачать напрямую
echo       Downloading Git installer...
set "GIT_INSTALLER=%TEMP%\git_installer.exe"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe' -OutFile '%GIT_INSTALLER%' -UseBasicParsing" 2>nul
if exist "%GIT_INSTALLER%" (
    echo       Running Git installer (silent)...
    "%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh" /PATHOPTION=CmdTools /SSHOPTION=OpenSSH
    timeout /t 15 /nobreak >nul
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    del "%GIT_INSTALLER%" >nul 2>nul
    echo       [OK] Git installed.
    goto :git_done
)

echo       [FAIL] Could not install Git automatically.
echo       Please install Git manually from https://git-scm.com/download/win
echo       Then run this script again.
pause
exit /b 1

:git_done
echo.

REM ═══════ 2. КЛОНИРУЕМ РЕПО ═══════
echo [2/5] Getting game files...

if exist "%INSTALL_DIR%\project.godot" (
    echo       [OK] Game files already exist. Updating...
    git -C "%INSTALL_DIR%" pull --rebase 2>nul
    goto :clone_done
)

echo       Cloning from GitHub...
git clone "%REPO_URL%" "%INSTALL_DIR%" 2>nul
if exist "%INSTALL_DIR%\project.godot" (
    echo       [OK] Game files downloaded.
    goto :clone_done
)

echo       [FAIL] Git clone failed.
echo       Check your internet connection and try again.
pause
exit /b 1

:clone_done
echo.

REM ═══════ 3. СКАЧИВАЕМ GODOT ═══════
echo [3/5] Checking Godot...

REM Ищем Godot где угодно
set "GODOT_EXE="

REM В папке игры
if exist "%INSTALL_DIR%\godot.exe" (
    set "GODOT_EXE=%INSTALL_DIR%\godot.exe"
    echo       [OK] Found godot.exe in game folder.
    goto :godot_done
)

REM В Downloads
for %%G in ("%USERPROFILE%\Downloads\Godot_v4*.exe") do (
    set "GODOT_EXE=%%G"
    echo       [OK] Found Godot in Downloads.
    goto :godot_done
)

REM На рабочем столе
for %%G in ("%USERPROFILE%\Desktop\Godot_v4*.exe") do (
    set "GODOT_EXE=%%G"
    echo       [OK] Found Godot on Desktop.
    goto :godot_done
)

REM В PATH
where godot >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set "GODOT_EXE=godot"
    echo       [OK] Godot found in PATH.
    goto :godot_done
)

echo       Godot not found. Downloading...
echo       URL: %GODOT_URL%

set "GODOT_ZIP=%INSTALL_DIR%\godot_temp.zip"

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%GODOT_URL%' -OutFile '%GODOT_ZIP%' -UseBasicParsing"

if not exist "%GODOT_ZIP%" (
    REM Fallback: curl
    curl -L -o "%GODOT_ZIP%" "%GODOT_URL%" 2>nul
)

if not exist "%GODOT_ZIP%" (
    echo       [FAIL] Could not download Godot.
    echo       Download manually from https://godotengine.org/download/windows/
    echo       Put the .exe into %INSTALL_DIR% and rename to godot.exe
    echo       Then run this script again.
    pause
    exit /b 1
)

echo       Downloaded. Extracting...

powershell -Command "Expand-Archive -Path '%GODOT_ZIP%' -DestinationPath '%INSTALL_DIR%' -Force" 2>nul

REM Находим распакованный .exe
set "FOUND_GODOT="
for %%G in ("%INSTALL_DIR%\Godot_v4*.exe") do set "FOUND_GODOT=%%G"

if defined FOUND_GODOT (
    copy /y "!FOUND_GODOT!" "%INSTALL_DIR%\godot.exe" >nul
    del "!FOUND_GODOT!" >nul 2>nul
    set "GODOT_EXE=%INSTALL_DIR%\godot.exe"
) else if exist "%INSTALL_DIR%\godot.exe" (
    set "GODOT_EXE=%INSTALL_DIR%\godot.exe"
) else (
    REM Возможно zip содержал просто exe с тем же именем
    REM Пробуем переименовать zip в exe (иногда Godot отдаёт как zip но это exe)
    copy /y "%GODOT_ZIP%" "%INSTALL_DIR%\godot.exe" >nul 2>nul
    set "GODOT_EXE=%INSTALL_DIR%\godot.exe"
)

del "%GODOT_ZIP%" >nul 2>nul

if not exist "%GODOT_EXE%" (
    echo       [FAIL] Extraction failed.
    pause
    exit /b 1
)

echo       [OK] Godot ready.

:godot_done
echo.

REM ═══════ 4. ЭКСПОРТИРУЕМ STANDALONE .EXE ═══════
echo [4/5] Building standalone game...

if exist "%INSTALL_DIR%\EdiblePlanet.exe" (
    echo       [OK] EdiblePlanet.exe already exists. Skipping build.
    goto :build_done
)

REM Создаём export_presets.cfg если нет
if not exist "%INSTALL_DIR%\export_presets.cfg" (
    echo       Creating export config...
    (
echo [preset.0]
echo.
echo name="Windows Desktop"
echo runnable=true
echo dedicated_server=false
echo custom_features=""
echo export_filter="all_resources"
echo include_filter=""
echo exclude_filter=""
echo export_path="./EdiblePlanet.exe"
echo encryption_include_filters=""
echo encryption_exclude_filters=""
echo encrypt_pck=false
echo encrypt_directory=false
echo script_export_mode=2
echo.
echo [preset.0.options]
echo.
echo custom_template/debug=""
echo custom_template/release=""
echo debug/export_console_wrapper=1
echo binary_format/embed_pck=true
echo texture_format/bptc=true
echo texture_format/s3tc=true
echo texture_format/etc=false
echo texture_format/etc2=false
echo binary_format/architecture="x86_64"
echo codesign/enable=false
echo application/icon="res://icon.svg"
echo application/console_wrapper_icon=""
echo application/file_version="1.0.0.0"
echo application/product_version="1.0.0.0"
echo application/company_name="EdiblePlanet"
echo application/product_name="Edible Planet"
echo application/file_description="Edible Planet: Cosmic Feast"
echo application/copyright="MIT"
    ) > "%INSTALL_DIR%\export_presets.cfg"
)

echo       Exporting (this takes 30-60 seconds)...

"%GODOT_EXE%" --headless --path "%INSTALL_DIR%" --export-release "Windows Desktop" "%INSTALL_DIR%\EdiblePlanet.exe" 2>nul

if exist "%INSTALL_DIR%\EdiblePlanet.exe" (
    echo       [OK] Build complete! EdiblePlanet.exe created.
) else (
    echo       [!] Headless export didn't work. Trying editor method...
    echo       Opening Godot editor. In Godot: Project -^> Export -^> Export Project
    echo       Save as EdiblePlanet.exe in %INSTALL_DIR%
    echo.
    echo       OR just press F5 to play right now!
    start "" "%GODOT_EXE%" --path "%INSTALL_DIR%"
    echo.
    echo       After you close Godot, run this script again — it will find EdiblePlanet.exe
    pause
    exit /b 0
)

:build_done
echo.

REM ═══════ 5. ЗАПУСКАЕМ ИГРУ ═══════
echo [5/5] Launching Edible Planet!
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║  GAME STARTING!                          ║
echo  ║  Have fun playing together!               ║
echo  ║                                          ║
echo  ║  Player 1: WASD = tilt planet             ║
echo  ║  Player 2: Mouse LMB/RMB = magnet         ║
echo  ║  (Change controls in game menu)           ║
echo  ╚══════════════════════════════════════════╝
echo.

start "" "%INSTALL_DIR%\EdiblePlanet.exe"

REM Создаём ярлык на рабочем столе
set "SHORTCUT=%USERPROFILE%\Desktop\Edible Planet.lnk"
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%INSTALL_DIR%\EdiblePlanet.exe'; $s.WorkingDirectory = '%INSTALL_DIR%'; $s.Description = 'Edible Planet: Cosmic Feast'; $s.Save()" 2>nul
if exist "%SHORTCUT%" (
    echo  [OK] Desktop shortcut created!
)

echo.
echo  Game installed to: %INSTALL_DIR%
echo  Desktop shortcut: Edible Planet
echo  Next time just double-click the shortcut!
echo.
echo  GitHub: https://github.com/kissabmi/EdiblePlanet
echo.
pause

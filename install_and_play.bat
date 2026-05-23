@echo off
chcp 65001 >nul
title Edible Planet — Auto-Install & Launch
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║   EDIBLE PLANET: COSMIC FEAST           ║
echo  ║   Auto-Install & Launch Script          ║
echo  ╚══════════════════════════════════════════╝
echo.

REM ─── 0. Find project folder (where this script lives) ───
set "PROJECT_DIR=%~dp0"
REM Remove trailing backslash
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

REM Go up one level if we're inside windows/ subfolder
for %%F in ("%PROJECT_DIR%") do set "PARENT=%%~dpF"
if exist "%PARENT%project.godot" set "PROJECT_DIR=%PARENT%"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

echo [*] Project directory: %PROJECT_DIR%
echo.

REM ─── 1. Check if standalone .exe already exists ───
if exist "%PROJECT_DIR%\EdiblePlanet.exe" (
    echo [✓] Found EdiblePlanet.exe — launching!
    start "" "%PROJECT_DIR%\EdiblePlanet.exe"
    goto :end
)

REM ─── 2. Check if Godot is already installed / in PATH ───
set "GODOT_EXE="

REM Check PATH
where godot >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set "GODOT_EXE=godot"
    echo [✓] Godot found in PATH.
    goto :run
)

REM Check common locations
if exist "%PROJECT_DIR%\godot.exe" (
    set "GODOT_EXE=%PROJECT_DIR%\godot.exe"
    echo [✓] Found godot.exe in project folder.
    goto :run
)
if exist "%PROJECT_DIR%\Godot_v4*.exe" (
    for %%G in ("%PROJECT_DIR%\Godot_v4*.exe") do set "GODOT_EXE=%%G"
    echo [✓] Found Godot in project folder.
    goto :run
)
if exist "%USERPROFILE%\Downloads\Godot_v4*.exe" (
    for %%G in ("%USERPROFILE%\Downloads\Godot_v4*.exe") do set "GODOT_EXE=%%G"
    echo [✓] Found Godot in Downloads.
    goto :run
)
if exist "%USERPROFILE%\Desktop\Godot_v4*.exe" (
    for %%G in ("%USERPROFILE%\Desktop\Godot_v4*.exe") do set "GODOT_EXE=%%G"
    echo [✓] Found Godot on Desktop.
    goto :run
)

REM ─── 3. Godot not found — download it ───
echo [!] Godot not found. Downloading automatically...
echo.

REM Determine latest Godot 4.x stable download URL
REM Using Godot 4.3 stable as known-good version
set "GODOT_VERSION=4.3"
set "GODOT_URL=https://github.com/godotengine/godot/releases/download/%GODOT_VERSION%-stable/Godot_v%GODOT_VERSION%-stable_win64.exe.zip"
set "GODOT_ZIP=%PROJECT_DIR%\godot_download.zip"
set "GODOT_TARGET=%PROJECT_DIR%\godot.exe"

echo [*] Download URL: %GODOT_URL%
echo [*] Saving to: %GODOT_ZIP%
echo.

REM Try with PowerShell (available on all modern Windows)
echo [*] Downloading with PowerShell...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%GODOT_URL%' -OutFile '%GODOT_ZIP%' -UseBasicParsing }" 2>nul

if not exist "%GODOT_ZIP%" (
    echo.
    echo [✗] PowerShell download failed. Trying with curl...
    curl -L -o "%GODOT_ZIP%" "%GODOT_URL%" 2>nul
)

if not exist "%GODOT_ZIP%" (
    echo.
    echo [✗] Automatic download failed.
    echo.
    echo     Please download Godot manually:
    echo     1. Go to https://godotengine.org/download/windows/
    echo     2. Download "Godot Engine" (Standard, 64-bit)
    echo     3. Save the .exe into: %PROJECT_DIR%
    echo     4. Rename it to: godot.exe
    echo     5. Run this script again.
    echo.
    pause
    goto :end
)

echo [✓] Download complete!
echo.

REM ─── 4. Extract if it's a zip ───
echo [*] Checking file type...

REM Check if it's a zip by extension
echo %GODOT_ZIP% | findstr /i ".zip" >nul
if %ERRORLEVEL% EQU 0 (
    echo [*] Extracting zip file...
    
    REM Try PowerShell extraction
    powershell -Command "Expand-Archive -Path '%GODOT_ZIP%' -DestinationPath '%PROJECT_DIR%' -Force" 2>nul
    
    REM Find the extracted .exe
    if exist "%PROJECT_DIR%\Godot_v4*.exe" (
        for %%G in ("%PROJECT_DIR%\Godot_v4*.exe") do (
            if not defined GODOT_EXE set "GODOT_EXE=%%G"
        )
        REM Rename to godot.exe for convenience
        if defined GODOT_EXE (
            copy /y "%GODOT_EXE%" "%GODOT_TARGET%" >nul
            set "GODOT_EXE=%GODOT_TARGET%"
        )
    ) else if exist "%PROJECT_DIR%\godot.exe" (
        set "GODOT_EXE=%GODOT_TARGET%"
    )
    
    REM Cleanup zip
    del "%GODOT_ZIP%" >nul 2>nul
    echo [✓] Extraction complete.
) else (
    REM It's already an exe (some Godot releases are direct exe)
    copy /y "%GODOT_ZIP%" "%GODOT_TARGET%" >nul
    del "%GODOT_ZIP%" >nul 2>nul
    set "GODOT_EXE=%GODOT_TARGET%"
    echo [✓] Godot exe ready.
)

echo.

REM ─── 5. Check if git repo needs cloning ───
if not exist "%PROJECT_DIR%\project.godot" (
    echo [!] Project files not found. Cloning from GitHub...
    git clone https://github.com/kissabmi/EdiblePlanet.git "%PROJECT_DIR%\EdiblePlanet" 2>nul
    if exist "%PROJECT_DIR%\EdiblePlanet\project.godot" (
        set "PROJECT_DIR=%PROJECT_DIR%\EdiblePlanet"
        echo [✓] Clone complete.
    ) else (
        echo [✗] Git clone failed. Please install git and try again.
        echo     Or manually download from: https://github.com/kissabmi/EdiblePlanet
        pause
        goto :end
    )
)

:run
REM ─── 6. Ask: run in editor or export standalone exe? ───
echo.
echo  How do you want to play?
echo.
echo  [1] Play now (opens Godot editor, press F5 to run)
echo  [2] Export as standalone .exe (double-click to play anytime, no Godot needed)
echo  [3] Just launch directly (headless run)
echo.

set /p CHOICE="Enter choice (1/2/3): "

if "%CHOICE%"=="1" (
    echo.
    echo [*] Opening Godot editor...
    echo     Press F5 or click the Play button to start the game!
    start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"
    goto :end
)

if "%CHOICE%"=="2" (
    echo.
    echo [*] Exporting standalone .exe...
    echo     This may take a minute...
    
    REM Create export presets if not exists
    if not exist "%PROJECT_DIR%\export_presets.cfg" (
        echo [!] Creating export configuration...
        powershell -Command "& { $cfg = @'
[preset.0]

name=\"Windows Desktop\"
runnable=true
dedicated_server=false
custom_features=\"\"
export_filter=\"all_resources\"
include_filter=\"\"
exclude_filter=\"\"
export_path=\"./EdiblePlanet.exe\"
encryption_include_filters=\"\"
encryption_exclude_filters=\"\"
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=\"\"
custom_template/release=\"\"
debug/export_console_wrapper=1
binary_format/embed_pck=true
texture_format/bptc=true
texture_format/s3tc=true
texture_format/etc=false
texture_format/etc2=false
binary_format/architecture=\"x86_64\"
codesign/enable=false
application/icon=\"res://icon.svg\"
application/console_wrapper_icon=\"\"
application/file_version=\"1.0.0.0\"
application/product_version=\"1.0.0.0\"
application/company_name=\"EdiblePlanet\"
application/product_name=\"Edible Planet\"
application/file_description=\"Edible Planet: Cosmic Feast\"
application/copyright=\"MIT\"
'@; Set-Content -Path '%PROJECT_DIR%\export_presets.cfg' -Value $cfg -Encoding UTF8 }"
    )
    
    REM Export the project
    "%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --export-release "Windows Desktop" "%PROJECT_DIR%\EdiblePlanet.exe" 2>nul
    
    if exist "%PROJECT_DIR%\EdiblePlanet.exe" (
        echo.
        echo [✓] Export complete! Launching EdiblePlanet.exe...
        start "" "%PROJECT_DIR%\EdiblePlanet.exe"
    ) else (
        echo.
        echo [✗] Headless export failed. Opening Godot editor instead...
        echo     In Godot: Project → Export → Add → Windows Desktop → Export Project
        start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"
    )
    goto :end
)

if "%CHOICE%"=="3" (
    echo.
    echo [*] Launching game directly...
    "%GODOT_EXE%" --path "%PROJECT_DIR%" --editor_scene res://scenes/main_menu.tscn 2>nul || (
        REM Fallback: open editor and let user press F5
        echo [!] Direct launch not available. Opening editor...
        start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"
    )
    goto :end
)

REM Default: just open editor
echo.
echo [*] Opening Godot editor...
start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"

:end
echo.
echo  Thanks for playing Edible Planet!
echo  GitHub: https://github.com/kissabmi/EdiblePlanet
echo.

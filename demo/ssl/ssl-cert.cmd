@echo off
setlocal EnableDelayedExpansion

echo ===================================================
echo     Local SSL Certificate Generator for Live Server
echo ===================================================

:: 1. Verify OpenSSL is available
where openssl >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] 'openssl' command was not found in your PATH.
    echo Please install OpenSSL or ensure its bin folder is added to your PATH.
    echo Tip: Git for Windows includes OpenSSL in C:\Program Files\Git\usr\bin
    exit /b 1
)

:: 2. Determine target output directory
:: Priority:
::  a) Current directory if it is named 'ssl'
::  b) Subdirectory '.\ssl' in current directory if it exists
::  c) Script directory if script is located inside an 'ssl' folder
::  d) Create '.\ssl' in current working directory
for %%I in ("%CD%") do set "CUR_NAME=%%~nxI"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "SCRIPT_PARENT_NAME=%%~nxI"

if /i "%CUR_NAME%"=="ssl" (
    set "OUT_DIR=%CD%"
) else if exist "%CD%\ssl" (
    set "OUT_DIR=%CD%\ssl"
) else if /i "%SCRIPT_PARENT_NAME%"=="ssl" (
    set "OUT_DIR=%SCRIPT_DIR%"
) else (
    set "OUT_DIR=%CD%\ssl"
    if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul
)

:: 3. Prompt for Hostname / Domain / IP
set "INPUT_HOST=%~1"
if "%INPUT_HOST%"=="" (
    echo.
    set /p "INPUT_HOST=Enter Hostname / Domain / IP [default: 127.0.0.1]: "
)

if "%INPUT_HOST%"=="" set "INPUT_HOST=127.0.0.1"

:: Trim spaces
for /f "tokens=* delims= " %%a in ("%INPUT_HOST%") do set "INPUT_HOST=%%a"

echo.
echo [*] Target Host: %INPUT_HOST%
echo [*] Output Folder: %OUT_DIR%

:: 4. Build Subject Alternative Name (SAN)
:: Check if host is an IPv4 address
echo %INPUT_HOST%| findstr /r "^[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$" >nul
if !errorlevel! equ 0 (
    if "%INPUT_HOST%"=="127.0.0.1" (
        set "SAN=IP:127.0.0.1,DNS:localhost"
    ) else (
        set "SAN=IP:%INPUT_HOST%,IP:127.0.0.1,DNS:localhost"
    )
) else (
    if /i "%INPUT_HOST%"=="localhost" (
        set "SAN=DNS:localhost,IP:127.0.0.1"
    ) else (
        set "SAN=DNS:%INPUT_HOST%,DNS:localhost,IP:127.0.0.1"
    )
)

echo [*] SAN Extension: %SAN%
echo.

set "KEY_FILE=%OUT_DIR%\%INPUT_HOST%.key"
set "CSR_FILE=%OUT_DIR%\%INPUT_HOST%.csr"
set "CRT_FILE=%OUT_DIR%\%INPUT_HOST%.crt"
set "SERVER_KEY=%OUT_DIR%\server.key"
set "SERVER_CRT=%OUT_DIR%\server.crt"

:: 5. Generate Private Key and CSR
echo [*] Step 1/3: Generating private key and CSR...
openssl req -new -newkey rsa:2048 -nodes -keyout "%KEY_FILE%" -out "%CSR_FILE%" -subj "/CN=%INPUT_HOST%" -addext "subjectAltName=%SAN%"
if !errorlevel! neq 0 (
    echo [ERROR] Failed to generate private key and CSR.
    exit /b 1
)

:: 6. Generate Self-Signed CRT (825 days validity)
echo [*] Step 2/3: Signing self-signed certificate...
openssl x509 -req -days 825 -in "%CSR_FILE%" -signkey "%KEY_FILE%" -out "%CRT_FILE%" -copy_extensions copy
if !errorlevel! neq 0 (
    echo [ERROR] Failed to sign certificate.
    exit /b 1
)

:: Also create standard server.key and server.crt convenience copies
copy /y "%KEY_FILE%" "%SERVER_KEY%" >nul
copy /y "%CRT_FILE%" "%SERVER_CRT%" >nul

:: 7. Add certificate to Windows Trusted Root store using certutil
echo.
echo [*] Step 3/3: Adding certificate to Windows Trusted Root Certification Authorities store...
echo [*] Executing: certutil -addstore -f "ROOT" "%CRT_FILE%"
certutil -addstore -f "ROOT" "%CRT_FILE%"
if !errorlevel! equ 0 (
    echo [*] Certificate successfully installed into Trusted Root Certification Authorities!
) else (
    echo.
    echo [NOTE] Administrator privileges are required to write to the System ROOT store.
    echo If access was denied, run this script as Administrator or run in an elevated prompt:
    echo     certutil -addstore -f "ROOT" "%CRT_FILE%"
)

echo.
echo ===================================================
echo [SUCCESS] Local SSL Certificate Created Successfully!
echo ===================================================
echo Host-specific files:
echo   - Key: %KEY_FILE%
echo   - CSR: %CSR_FILE%
echo   - CRT: %CRT_FILE%
echo.
echo Convenience standard files:
echo   - Key: %SERVER_KEY%
echo   - CRT: %SERVER_CRT%
echo.
echo VS Code Live Server Configuration:
echo ---------------------------------------------------
echo Add this to your .vscode/settings.json:
echo.
echo {
echo   "liveServer.settings.https": {
echo     "enable": true,
echo     "cert": "./ssl/server.crt",
echo     "key": "./ssl/server.key",
echo     "passphrase": ""
echo   }
echo }
echo ===================================================
echo.

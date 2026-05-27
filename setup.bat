@echo off
title SupportBot Setup
setlocal enabledelayedexpansion

set "BASEDIR=%~dp0"

echo ============================================================
echo   SupportBot - IT Support Assistant Setup
echo ============================================================
echo.

:: -----------------------------------------------------------
:: Step 1: Check Docker is running
:: -----------------------------------------------------------
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running.
    echo         Start Docker Desktop, then run this script again.
    pause
    exit /b 1
)
echo [OK] Docker is running.

:: -----------------------------------------------------------
:: Step 2: Pull image from Docker Hub (no login needed)
:: -----------------------------------------------------------
docker image inspect hongzhili40526/supportbot:latest >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [INFO] Pulling SupportBot image from Docker Hub...
    docker pull hongzhili40526/supportbot:latest
)
docker image inspect hongzhili40526/supportbot:latest >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Pull failed. Check your internet connection.
    pause
    exit /b 1
)
echo [OK] SupportBot image found.

:: -----------------------------------------------------------
:: Step 3: Check kb.json exists
:: -----------------------------------------------------------
if not exist "!BASEDIR!kb.json" (
    echo.
    echo [ERROR] kb.json not found in this folder.
    echo.
    echo   Download from OneDrive - open in browser, requires corporate login.
    echo   Save as "kb.json" in this folder, then run setup.bat again.
    echo.
    pause
    exit /b 1
)
echo [OK] Knowledge base found.

:: -----------------------------------------------------------
:: Step 4: Check .env exists (pre-configured from OneDrive)
:: -----------------------------------------------------------
:: Auto-rename if downloaded with OneDrive filename (handles duplicates like (2), (3), etc.)
if not exist "!BASEDIR!.env" (
    for %%F in ("!BASEDIR!supportbot-env*.env") do (
        move "%%F" "!BASEDIR!.env" >nul
        echo [OK] Renamed %%~nxF to .env
        goto :env_found
    )
)
:env_found
if not exist "!BASEDIR!.env" (
    echo.
    echo [ERROR] .env not found in this folder.
    echo.
    echo   Download from OneDrive - open in browser, requires corporate login.
    echo   Save the .env file in this folder, then run setup.bat again.
    echo.
    echo   The .env file contains Ollama server URLs and model config.
    echo   No credentials are needed for SupportBot.
    echo.
    pause
    exit /b 1
)
echo [OK] Configuration found.

:: -----------------------------------------------------------
:: Step 5: Run the container
:: -----------------------------------------------------------
echo.
echo ============================================================
echo   Starting SupportBot...
echo ============================================================

:: Stop existing container
docker stop supportbot >nul 2>&1
docker rm supportbot >nul 2>&1

:: Run container
docker run -d --name supportbot ^
    -p 5050:8080 ^
    --memory 1024m ^
    --cpus 2 ^
    --restart unless-stopped ^
    --env-file "!BASEDIR!.env" ^
    -v "!BASEDIR!kb.json:/app/kb.json" ^
    hongzhili40526/supportbot:latest

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to start container. Run: docker logs supportbot
    pause
    exit /b 1
)

:: Wait and check
echo Waiting for startup...
timeout /t 10 /nobreak >nul

:: Verify the container is actually healthy
docker logs supportbot 2>&1 | findstr /C:"STARTUP FAILED" >nul
if %errorlevel% equ 0 (
    echo.
    echo [ERROR] Container started but configuration is wrong!
    echo.
    echo   Checking .env file...
    echo   ---
    type "!BASEDIR!.env"
    echo   ---
    echo.
    echo   The .env file may have wrong encoding (BOM character from OneDrive).
    echo   Fix: Open .env in Notepad, Save As, choose "UTF-8" (not "UTF-8 with BOM").
    echo   Or delete .env and recreate it with this content:
    echo.
    echo     Ollama__Hosts__0=http://10.222.19.229:11434
    echo     Ollama__Hosts__1=http://10.222.10.30:11434
    echo.
    docker stop supportbot >nul 2>&1
    docker rm supportbot >nul 2>&1
    pause
    exit /b 1
)

:: Check health endpoint
curl -s http://localhost:5050/health | findstr /C:"ok" >nul
if %errorlevel% equ 0 (
    echo [OK] Health check passed - both Ollama servers reachable.
) else (
    echo [WARN] Health check failed - Ollama servers may not be reachable.
    echo        Make sure you are on the Volvo network or VPN.
)

echo.
echo ============================================================
echo   SupportBot is running!
echo.
echo   Open in browser: http://localhost:5050/
echo   Health check:    http://localhost:5050/health
echo.
echo   Logs:    docker logs -f supportbot
echo   Stop:    docker stop supportbot
echo   Restart: docker start supportbot
echo ============================================================
echo.
pause

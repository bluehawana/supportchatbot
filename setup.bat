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
:: Step 2: Pull latest image from Docker Hub (always pull to get updates)
:: -----------------------------------------------------------
echo.
echo [INFO] Cleaning up old images and containers...
docker stop supportbot >nul 2>&1
docker rm -f supportbot >nul 2>&1
docker rmi -f hongzhili40526/supportbot:latest >nul 2>&1
docker image prune -f >nul 2>&1
echo [INFO] Pulling fresh image from Docker Hub...
docker pull hongzhili40526/supportbot:latest
if %errorlevel% neq 0 (
    echo [ERROR] Pull failed. Check your internet connection.
    pause
    exit /b 1
)
echo [OK] SupportBot image ready (latest version).

:: -----------------------------------------------------------
:: -----------------------------------------------------------
:: Step 3: kb.json is baked into the Docker image — no download needed
:: -----------------------------------------------------------
echo [OK] Knowledge base included in Docker image.

:: -----------------------------------------------------------
:: Step 4: Check .env exists and has content
:: -----------------------------------------------------------
set "ENVFILE="
if exist "!BASEDIR!.env" (
    set "ENVFILE=!BASEDIR!.env"
)
for %%F in ("!BASEDIR!supportbot-env*.env") do (
    set "ENVFILE=%%F"
)

if "!ENVFILE!"=="" (
    echo.
    echo [ERROR] .env not found in this folder.
    echo.
    echo   Create a .env file in this folder with the content from Teams chat.
    echo   Save as UTF-8 in Notepad.
    echo.
    pause
    exit /b 1
)

:: Check file is not empty
for %%A in ("!ENVFILE!") do set ENVSIZE=%%~zA
if "!ENVSIZE!"=="0" (
    echo.
    echo [ERROR] .env file is empty!
    echo.
    echo   Open .env in Notepad and paste the configuration from Teams chat.
    echo   Save the file, then run setup.bat again.
    echo.
    pause
    exit /b 1
)

:: Check it contains Ollama host config
findstr /I /C:"Ollama" "!ENVFILE!" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] .env file does not contain Ollama configuration!
    echo.
    echo   The .env must contain at least:
    echo     Ollama__Hosts__0=http://...
    echo.
    echo   Paste the correct content from Teams chat.
    echo.
    pause
    exit /b 1
)
echo [OK] Configuration found and valid.

:: -----------------------------------------------------------
:: Step 5: Run the container
:: -----------------------------------------------------------
echo.
echo ============================================================
echo   Starting SupportBot...
echo ============================================================

:: Run container
docker run -d --name supportbot ^
    -p 5050:8080 ^
    --memory 1024m ^
    --cpus 2 ^
    --restart unless-stopped ^
    --env-file "!ENVFILE!" ^
    hongzhili40526/supportbot:latest

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to start container. Run: docker logs supportbot
    pause
    exit /b 1
)

:: Wait for startup
echo Waiting for startup...
powershell -NoProfile -Command "Start-Sleep -Seconds 5" >nul 2>nul

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
echo   If the page does not load, check:
echo     - Are you on the Volvo network or VPN?
echo     - Run: docker logs supportbot --tail 20
echo.
pause

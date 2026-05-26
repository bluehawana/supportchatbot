@echo off
title SupportBot Setup
setlocal

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
    if %errorlevel% neq 0 (
        echo [ERROR] Pull failed. Check your internet connection.
        pause
        exit /b 1
    )
)
echo [OK] SupportBot image found.

:: -----------------------------------------------------------
:: Step 3: Check kb.json exists
:: -----------------------------------------------------------
if not exist "%~dp0kb.json" (
    echo.
    echo [ERROR] kb.json not found in this folder.
    echo.
    echo   Download from OneDrive (open in browser - requires corporate login):
    echo   Save as "kb.json" in this folder, then run setup.bat again.
    echo.
    pause
    exit /b 1
)
echo [OK] Knowledge base found.

:: -----------------------------------------------------------
:: Step 4: Check .env exists (pre-configured from OneDrive)
:: -----------------------------------------------------------
if not exist "%~dp0.env" (
    echo.
    echo [ERROR] .env not found in this folder.
    echo.
    echo   Download from OneDrive (open in browser - requires corporate login):
    echo   Save as ".env" in this folder, then run setup.bat again.
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
    --env-file "%~dp0.env" ^
    -v "%~dp0kb.json:/app/kb.json:ro" ^
    hongzhili40526/supportbot:latest

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to start container. Run: docker logs supportbot
    pause
    exit /b 1
)

:: Wait and check
echo Waiting for startup...
timeout /t 8 /nobreak >nul

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

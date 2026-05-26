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
:: Step 2: Check if supportbot image exists, load from .tar
:: -----------------------------------------------------------
docker image inspect ghcr.io/harvad-li_volvo/supportbot:latest >nul 2>&1
if %errorlevel% neq 0 (
    docker image inspect supportbot:latest >nul 2>&1
    if %errorlevel% neq 0 (
        if not exist "%~dp0supportbot-image.tar" (
            echo.
            echo [INFO] Downloading SupportBot image...
            curl --ssl-no-revoke -L -o "%~dp0supportbot-image.tar" "https://volvogroup-my.sharepoint.com/:u:/g/personal/harvad_li_consultant_volvo_com/IQA2o1R2vsoHTrLmLczyCVBmAagYlaMf-XUsO9vO7YLNV2s?download=1"
            if %errorlevel% neq 0 (
                echo [ERROR] Download failed. Make sure you are on the Volvo network.
                pause
                exit /b 1
            )
        )
        echo.
        echo [INFO] Loading SupportBot image from supportbot-image.tar...
        docker load -i "%~dp0supportbot-image.tar"
        docker image inspect ghcr.io/harvad-li_volvo/supportbot:latest >nul 2>&1
        if %errorlevel% neq 0 (
            docker image inspect supportbot:latest >nul 2>&1
            if %errorlevel% neq 0 (
                echo [ERROR] Failed to load image from .tar file.
                pause
                exit /b 1
            )
        )
    )
)
echo [OK] SupportBot image found.

:: -----------------------------------------------------------
:: Step 3: Check kb.json exists
:: -----------------------------------------------------------
if not exist "%~dp0\kb.json" (
    echo.
    echo [INFO] Downloading knowledge base from OneDrive...
    curl --ssl-no-revoke -L -o "%~dp0kb.json" "https://volvogroup-my.sharepoint.com/:u:/g/personal/harvad_li_consultant_volvo_com/IQCYuXfVFOcDRKg-Kk4AF6PEAUN7KAQ1eDhOUmvVtFRXyu4?download=1"
    if %errorlevel% neq 0 (
        echo [ERROR] Download failed. Download kb.json manually from OneDrive and place in this folder.
        pause
        exit /b 1
    )
)
echo [OK] Knowledge base found.

:: -----------------------------------------------------------
:: Step 4: Load existing config or prompt for new
:: -----------------------------------------------------------
set ENV_FILE=%~dp0.env

if exist "%ENV_FILE%" (
    echo.
    echo Found existing config: %ENV_FILE%
    set /p REUSE="Use existing config? (Y/n): "
    if /i "%REUSE%" neq "n" goto run
)

echo.
echo -----------------------------------------------------------
echo   Enter your configuration
echo -----------------------------------------------------------
echo.
echo   You need the Ollama server URL from your team lead.
echo   Default: http://10.222.19.229:11434
echo.

set /p OLLAMA_HOST="Primary Ollama URL (Enter for default): "
if "%OLLAMA_HOST%"=="" set OLLAMA_HOST=http://10.222.19.229:11434

set /p OLLAMA_HOST2="Secondary Ollama URL (Enter to skip): "

:: Write .env file
echo Ollama__Hosts__0=%OLLAMA_HOST%> "%ENV_FILE%"
if not "%OLLAMA_HOST2%"=="" echo Ollama__Hosts__1=%OLLAMA_HOST2%>> "%ENV_FILE%"
echo Ollama__ChatModel=qwen3.5:35b>> "%ENV_FILE%"
echo Ollama__FallbackChatModel=mistral-small3.1>> "%ENV_FILE%"
echo Ollama__EmbeddingModel=nomic-embed-text>> "%ENV_FILE%"
echo.
echo [OK] Config saved. This file is git-ignored and stays on your machine only.

:: -----------------------------------------------------------
:: Step 5: Run the container
:: -----------------------------------------------------------
:run

echo.
echo ============================================================
echo   Starting SupportBot...
echo ============================================================

:: Stop existing container
docker stop supportbot >nul 2>&1
docker rm supportbot >nul 2>&1

:: Determine which image name to use
set IMAGE=ghcr.io/harvad-li_volvo/supportbot:latest
docker image inspect %IMAGE% >nul 2>&1
if %errorlevel% neq 0 set IMAGE=supportbot:latest

:: Run container
docker run -d --name supportbot ^
    -p 5050:8080 ^
    --memory 1024m ^
    --cpus 2 ^
    --restart unless-stopped ^
    --env-file "%~dp0.env" ^
    -v "%~dp0kb.json:/app/kb.json:ro" ^
    %IMAGE%

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

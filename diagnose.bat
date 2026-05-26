@echo off
title SupportBot Diagnostics
setlocal

set OUTFILE=%~dp0supportbot-diagnostics.txt

echo ============================================================
echo   SupportBot Diagnostics
echo   Collecting info... please wait.
echo ============================================================

echo ============================================================> "%OUTFILE%"
echo   SupportBot Diagnostics Report>> "%OUTFILE%"
echo   Generated: %date% %time%>> "%OUTFILE%"
echo   Machine: %COMPUTERNAME%>> "%OUTFILE%"
echo   User: %USERNAME%>> "%OUTFILE%"
echo ============================================================>> "%OUTFILE%"
echo.>> "%OUTFILE%"

echo --- Docker Version --->> "%OUTFILE%"
docker --version >> "%OUTFILE%" 2>&1
echo.>> "%OUTFILE%"

echo --- Container Status --->> "%OUTFILE%"
docker ps -a --filter name=supportbot --format "table {{.ID}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" >> "%OUTFILE%" 2>&1
echo.>> "%OUTFILE%"

echo --- Environment (sanitized) --->> "%OUTFILE%"
docker exec supportbot printenv 2>&1 | findstr /i "Ollama ASPNET" >> "%OUTFILE%" 2>&1
echo.>> "%OUTFILE%"

echo --- Health Check --->> "%OUTFILE%"
curl -s http://localhost:5050/health >> "%OUTFILE%" 2>&1
echo.>> "%OUTFILE%"
echo.>> "%OUTFILE%"

echo --- Last 50 Container Logs --->> "%OUTFILE%"
docker logs supportbot --tail 50 >> "%OUTFILE%" 2>&1
echo.>> "%OUTFILE%"

echo --- Network: Can reach Ollama? --->> "%OUTFILE%"
docker exec supportbot wget -q -O - --timeout=5 http://10.222.19.229:11434/api/tags >> "%OUTFILE%" 2>&1
echo.>> "%OUTFILE%"
docker exec supportbot wget -q -O - --timeout=5 http://10.222.10.30:11434/api/tags >> "%OUTFILE%" 2>&1
echo.>> "%OUTFILE%"

echo --- kb.json Info --->> "%OUTFILE%"
if exist "%~dp0kb.json" (
    echo File exists, size:>> "%OUTFILE%"
    for %%A in ("%~dp0kb.json") do echo   %%~zA bytes>> "%OUTFILE%"
) else (
    echo kb.json NOT FOUND>> "%OUTFILE%"
)
echo.>> "%OUTFILE%"

echo ============================================================>> "%OUTFILE%"
echo   END OF REPORT>> "%OUTFILE%"
echo ============================================================>> "%OUTFILE%"

echo.
echo ============================================================
echo   Done! Report saved to:
echo   %OUTFILE%
echo.
echo   Please send this file to the SupportBot team via Teams.
echo ============================================================
echo.
pause

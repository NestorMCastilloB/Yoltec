@echo off
chcp 65001 >nul
title Yoltec Stopper

echo.
echo ============================================
echo   Deteniendo servicios de Yoltec...
echo ============================================
echo.

for %%P in (8000 4200 5000) do (
    echo Liberando puerto %%P...
    for /f "tokens=5" %%A in ('netstat -ano ^| findstr ":%%P " ^| findstr "LISTENING"') do (
        taskkill /F /PID %%A >nul 2>&1
    )
)

taskkill /FI "WINDOWTITLE eq Yoltec Backend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq Yoltec Frontend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq Yoltec IA*" /F >nul 2>&1

echo.
echo Servicios detenidos.
echo.
timeout /t 3 /nobreak >nul
exit

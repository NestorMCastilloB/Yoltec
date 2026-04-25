@echo off
chcp 65001 >nul
title Yoltec Launcher

echo.
echo ============================================
echo   Arrancando Yoltec...
echo ============================================
echo.

echo [1/3] Backend Laravel...
start "Yoltec Backend" cmd /k "cd /d C:\Proyectos\Yoltec\backend && php artisan serve --host=127.0.0.1 --port=8000"

timeout /t 3 /nobreak >nul

echo [2/3] Servicio IA (FastAPI)...
start "Yoltec IA" cmd /k "cd /d C:\Proyectos\Yoltec\IA && call venv\Scripts\activate.bat && uvicorn app:app --host=0.0.0.0 --port=5000"

timeout /t 3 /nobreak >nul

echo [3/3] Frontend Angular...
start "Yoltec Frontend" cmd /k "cd /d C:\Proyectos\Yoltec\frontend && ng serve --host=0.0.0.0 --port=4200"

echo.
echo ============================================
echo   Servicios arrancando en ventanas aparte
echo ============================================
echo   Backend:  http://127.0.0.1:8000
echo   Frontend: http://localhost:4200
echo   IA:       http://127.0.0.1:5000
echo ============================================
echo.
echo El frontend tarda 30-60s en compilar la primera vez.
echo Cierra las 3 ventanas (o usa stop-yoltec.bat) para detener todo.
echo.
echo Abriendo navegador en http://localhost:4200 en 15 segundos...
timeout /t 15 /nobreak >nul
start http://localhost:4200

exit

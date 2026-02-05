@echo off
REM Simple Docker Build Script for WebApp Wrapper (Windows)
setlocal enabledelayedexpansion

echo 🚀 WebApp Wrapper Docker Tools
echo ===============================

REM Check Docker
docker info >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo ❌ Docker not running. Start Docker Desktop first.
    pause
    exit /b 1
)
echo ✅ Docker is running

:menu
echo.
echo Choose an option:
echo 1. Configure App (URL and Name)
echo 2. Build APK 
echo 3. Open Container Shell
echo 4. View Status
echo 0. Exit
echo.
set /p choice="Enter choice (0-4): "

if "%choice%"=="1" goto configure
if "%choice%"=="2" goto build
if "%choice%"=="3" goto shell
if "%choice%"=="4" goto status
if "%choice%"=="0" goto exit
echo Invalid choice!
goto menu

:configure
echo.
echo 🔧 Configure Your App
echo ====================
docker-compose exec webapp-wrapper python3 configure_app.py
echo.
pause
goto menu

:build
echo.
echo 📱 Building APK...
echo ==================
echo Checking EAS login...
docker-compose exec webapp-wrapper eas whoami
if !ERRORLEVEL! neq 0 (
    echo.
    echo Please login to EAS:
    docker-compose exec webapp-wrapper eas login
)
echo.
echo Starting build...
docker-compose exec webapp-wrapper eas build --platform android --non-interactive
echo.
echo ✅ Build process completed!
pause
goto menu

:shell
echo.
echo 🐚 Opening Container Shell...
docker-compose exec webapp-wrapper bash
goto menu

:status
echo.
echo 📊 Current Status
echo =================
echo Docker containers:
docker-compose ps
echo.
echo Current configuration:
docker-compose exec webapp-wrapper python3 -c "
import json
import os

# Read URL
app_tsx = '/app/App.tsx'
if os.path.exists(app_tsx):
    with open(app_tsx, 'r') as f:
        for line in f:
            if 'APP_URL' in line and '=' in line:
                url = line.split('=')[1].strip().strip(\"';\\\"\"')
                print(f'App URL: {url}')
                break

# Read name
app_json = '/app/app.json'
if os.path.exists(app_json):
    with open(app_json, 'r') as f:
        config = json.load(f)
        name = config.get('expo', {}).get('name', '')
        print(f'App Name: {name}')
"
echo.
pause
goto menu

:exit
echo 👋 Goodbye!
exit /b 0
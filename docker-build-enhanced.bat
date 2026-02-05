@echo off
REM Enhanced Docker Build Script for WebApp Wrapper (Windows)
REM This script runs commands directly or through Docker

setlocal enabledelayedexpansion

echo 🚀 Starting WebApp Wrapper Docker Tools...

REM Check if Docker is running
docker info >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo ❌ Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo ✅ Docker is running

REM Menu
:menu
echo.
echo === WebApp Wrapper Docker Tools ===
echo 1. Build Docker image
echo 2. Start services
echo 3. Install dependencies  
echo 4. Configure app (URL and name)
echo 5. Run EAS build
echo 6. Open container shell
echo 7. View logs
echo 8. Stop services
echo 9. Cleanup
echo 10. Run local Python GUI (if Python installed)
echo 0. Exit
echo.

set /p choice="Choose an option (0-10): "

if "%choice%"=="1" goto build_image
if "%choice%"=="2" goto start_services
if "%choice%"=="3" goto install_dependencies
if "%choice%"=="4" goto configure_app
if "%choice%"=="5" goto run_eas_build
if "%choice%"=="6" goto open_shell
if "%choice%"=="7" goto view_logs
if "%choice%"=="8" goto stop_services
if "%choice%"=="9" goto cleanup
if "%choice%"=="10" goto run_local_gui
if "%choice%"=="0" goto exit

echo ❌ Invalid option. Please choose 0-10.
goto menu

:build_image
echo 🏗️  Building Docker image...
docker-compose build webapp-wrapper
if !ERRORLEVEL! equ 0 (
    echo ✅ Docker image built successfully
) else (
    echo ❌ Failed to build Docker image
)
goto menu

:start_services
echo 🚀 Starting Docker services...
docker-compose up -d webapp-wrapper
if !ERRORLEVEL! equ 0 (
    echo ✅ Services started
) else (
    echo ❌ Failed to start services
)
goto menu

:install_dependencies
echo 📦 Installing Node.js dependencies...
docker-compose exec webapp-wrapper npm install
if !ERRORLEVEL! equ 0 (
    echo ✅ Dependencies installed
) else (
    echo ❌ Failed to install dependencies
)
goto menu

:configure_app
echo 🔧 Configure your WebApp Wrapper...
echo.
set /p app_url="Enter your app URL (e.g., http://192.168.1.109/NEWKIOSK): "
set /p app_name="Enter your app name (e.g., My Kiosk App): "

if "%app_url%"=="" (
    echo ❌ App URL cannot be empty!
    goto menu
)
if "%app_name%"=="" (
    echo ❌ App name cannot be empty!
    goto menu
)

echo ⚙️  Updating configuration...

REM Update App.tsx
docker-compose exec webapp-wrapper bash -c "sed -i \"s|const APP_URL = '.*';|const APP_URL = '%app_url%';|g\" App.tsx"

REM Update app.json name
docker-compose exec webapp-wrapper bash -c "python3 -c \"
import json
with open('app.json', 'r') as f: 
    config = json.load(f)
config['expo']['name'] = '%app_name%'
if 'android' in config['expo']:
    config['expo']['android']['label'] = '%app_name%'
with open('app.json', 'w') as f:
    json.dump(config, f, indent=2)
print('✅ Configuration updated!')
\""

echo ✅ App configured successfully!
echo    App URL: %app_url%
echo    App Name: %app_name%
goto menu

:run_eas_build
echo 📱 Running EAS build...
echo.
echo 🔐 Checking EAS login status...
docker-compose exec webapp-wrapper eas whoami
if !ERRORLEVEL! neq 0 (
    echo Please login to EAS first:
    docker-compose exec webapp-wrapper eas login
)

echo 🏗️ Starting build process...
docker-compose exec webapp-wrapper eas build --platform android --non-interactive
if !ERRORLEVEL! equ 0 (
    echo ✅ EAS build completed successfully!
    echo 📱 Your APK will be available in your Expo dashboard
) else (
    echo ❌ EAS build failed. Check the logs above.
)
goto menu

:open_shell
echo 🐚 Opening container shell...
docker-compose exec webapp-wrapper bash
goto menu

:view_logs
docker-compose logs -f webapp-wrapper
goto menu

:stop_services
echo ⏹️  Stopping services...
docker-compose stop
if !ERRORLEVEL! equ 0 (
    echo ✅ Services stopped
) else (
    echo ❌ Failed to stop services
)
goto menu

:cleanup
echo 🧹 Cleaning up...
docker-compose down
if !ERRORLEVEL! equ 0 (
    echo ✅ Cleanup completed
) else (
    echo ❌ Cleanup failed
)
goto menu

:run_local_gui
echo 🖥️  Checking for local Python installation...
python --version >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo ✅ Python found locally. Starting GUI...
    python eas_build_docker.py
) else (
    echo ❌ Python not found locally. 
    echo    Use Docker options instead, or install Python locally.
)
goto menu

:exit
echo 👋 Goodbye!
pause
exit /b 0
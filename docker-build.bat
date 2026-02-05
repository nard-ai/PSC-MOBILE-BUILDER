@echo off
REM Docker Build Script for WebApp Wrapper (Windows)
REM This script runs the EAS build process inside a Docker container

setlocal enabledelayedexpansion

echo 🚀 Starting WebApp Wrapper Docker Build...

REM Function to check if Docker is running
:check_docker
docker info >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo ❌ Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo ✅ Docker is running

REM Handle command line arguments
if "%1"=="build" goto build_image
if "%1"=="start" goto start_services
if "%1"=="install" goto install_dependencies
if "%1"=="gui" goto run_python_gui
if "%1"=="eas-build" goto run_eas_build
if "%1"=="shell" goto open_shell
if "%1"=="logs" goto view_logs
if "%1"=="stop" goto stop_services
if "%1"=="cleanup" goto cleanup

REM Interactive menu
:menu
echo.
echo === WebApp Wrapper Docker Tools ===
echo 1. Build Docker image
echo 2. Start services
echo 3. Install dependencies
echo 4. Run Python GUI tool
echo 5. Run EAS build
echo 6. Open container shell
echo 7. View logs
echo 8. Stop services
echo 9. Cleanup
echo 0. Exit
echo.

set /p choice="Choose an option (0-9): "

if "%choice%"=="1" goto build_image
if "%choice%"=="2" goto start_services
if "%choice%"=="3" goto install_dependencies
if "%choice%"=="4" goto run_python_gui
if "%choice%"=="5" goto run_eas_build
if "%choice%"=="6" goto open_shell
if "%choice%"=="7" goto view_logs
if "%choice%"=="8" goto stop_services
if "%choice%"=="9" goto cleanup
if "%choice%"=="0" goto exit

echo ❌ Invalid option. Please choose 0-9.
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

:run_python_gui
echo 🖥️  Starting Python GUI tool...
docker-compose exec webapp-wrapper python3 eas_build.py
goto menu

:run_eas_build
echo 📱 Running EAS build inside container...
echo 🔐 Checking EAS login status...
docker-compose exec webapp-wrapper eas whoami
if !ERRORLEVEL! neq 0 (
    echo Please login to EAS first:
    docker-compose exec webapp-wrapper eas login
)
docker-compose exec webapp-wrapper eas build --platform android --non-interactive
if !ERRORLEVEL! equ 0 (
    echo ✅ EAS build completed
) else (
    echo ❌ EAS build failed
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

:exit
echo 👋 Goodbye!
pause
exit /b 0
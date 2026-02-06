@echo off
REM ============================================
REM  PSC Mobile Builder - Launcher
REM ============================================
REM  This script starts the Mobile App Builder
REM  Flask web application.
REM ============================================

title PSC Mobile Builder

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo.
echo ============================================
echo   PSC Mobile Builder
echo ============================================
echo.

REM Check if runtime exists
if not exist "runtime\python\python.exe" (
    echo ERROR: Python runtime not found!
    echo Please run the setup scripts first:
    echo   1. cd setup
    echo   2. .\download_python.ps1
    echo   3. .\download_node.ps1
    echo   4. .\install_pip_packages.ps1
    echo   5. .\install_npm_packages.ps1
    echo.
    pause
    exit /b 1
)

if not exist "runtime\node\node.exe" (
    echo ERROR: Node.js runtime not found!
    echo Please run the setup scripts first.
    echo.
    pause
    exit /b 1
)

echo Starting the builder...
echo.
echo Opening browser at http://localhost:5000
echo Press Ctrl+C to stop the server.
echo.

REM Run the Flask application
"runtime\python\python.exe" -c "import sys; sys.path.insert(0, r'%SCRIPT_DIR%'); from builder.app import run_server; run_server(open_browser_on_start=True)"

pause

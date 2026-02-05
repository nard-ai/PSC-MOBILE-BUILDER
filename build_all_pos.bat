@echo off
REM POS System Docker Setup Guide
echo 🏪 POS System Mobile App Builder Setup (Docker Method)
echo ====================================================

echo.
echo 📋 What each POS computer needs:
echo.
echo 1. Install Docker Desktop (one-time setup)
echo 2. Copy this entire project folder to POS computer
echo 3. Run the Docker commands below
echo.
echo 🖥️  On each POS computer:
echo.
echo Step 1: Install Docker Desktop
echo   - Download from: https://www.docker.com/products/docker-desktop
echo   - Install and start Docker Desktop
echo.
echo Step 2: Copy project folder to: C:\WebAppWrapper\
echo.
echo Step 3: Run these commands:
echo   cd C:\WebAppWrapper
echo   docker-compose up -d webapp-wrapper
echo   .\docker-simple.bat
echo.
echo Step 4: Configure each POS system:
echo   - Choose option 1 (Configure App)
echo   - Enter POS URL (http://localhost/pos or network IP)
echo   - Enter app name
echo   - Choose option 2 (Build APK)
echo.
echo ✅ Benefits of Docker approach:
echo - Only Docker needs to be installed (not Node.js, Python, EAS CLI separately)
echo - Same exact environment on all POS computers
echo - Easy updates (just update Docker image)
echo - No version conflicts between different tools
echo.
echo 📝 Example POS configurations:
echo.
echo POS Computer 1:
echo   URL: http://localhost/cashier
echo   Name: Cashier Terminal
echo.
echo POS Computer 2: 
echo   URL: http://localhost/inventory  
echo   Name: Inventory Terminal
echo.
echo POS Computer 3:
echo   URL: http://192.168.1.100/reports
echo   Name: Manager Reports
echo.
echo 🔧 Alternative (if Docker not preferred):
echo Each POS computer would need to install:
echo - Node.js LTS
echo - Python 3.9+
echo - EAS CLI: npm install -g eas-cli
echo - Git
echo.
pause
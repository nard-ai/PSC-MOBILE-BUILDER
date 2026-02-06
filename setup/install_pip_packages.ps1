# PSC Mobile Builder - Install Python Packages

$ErrorActionPreference = "Stop"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$PYTHON_DIR = Join-Path $RUNTIME_DIR "python"
$PYTHON_EXE = Join-Path $PYTHON_DIR "python.exe"

# Required packages
$PACKAGES = @(
    "flask",
    "requests",
    "pillow"
)

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Python Packages" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Python exists
if (-not (Test-Path $PYTHON_EXE)) {
    Write-Host "[X] Python not found at: $PYTHON_EXE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run download_python.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Verify Python works
Write-Host "[i] Checking Python installation..." -ForegroundColor Cyan
$pythonVersion = & $PYTHON_EXE --version 2>&1
Write-Host "[OK] Found Python: $pythonVersion" -ForegroundColor Green

# Upgrade pip
Write-Host "[i] Upgrading pip..." -ForegroundColor Cyan
try {
    & $PYTHON_EXE -m pip install --upgrade pip --quiet --no-warn-script-location 2>&1 | Out-Null
    Write-Host "[OK] pip upgraded" -ForegroundColor Green
}
catch {
    Write-Host "[!] Could not upgrade pip (may already be latest)" -ForegroundColor Yellow
}

# Install packages
Write-Host ""
Write-Host "[i] Installing required packages..." -ForegroundColor Cyan
Write-Host ""

$allSuccess = $true

foreach ($package in $PACKAGES) {
    Write-Host "[i] Installing $package..." -ForegroundColor Cyan
    try {
        & $PYTHON_EXE -m pip install $package --quiet --no-warn-script-location 2>&1 | Out-Null
        Write-Host "[OK] $package installed" -ForegroundColor Green
    }
    catch {
        Write-Host "[X] Failed to install $package" -ForegroundColor Red
        $allSuccess = $false
    }
}

# Verify Flask
Write-Host ""
Write-Host "[i] Verifying Flask (for web UI)..." -ForegroundColor Cyan
try {
    $flaskTest = & $PYTHON_EXE -c "import flask; print('OK')" 2>&1
    if ($flaskTest -match "OK") {
        Write-Host "[OK] Flask is available" -ForegroundColor Green
    }
    else {
        throw "Flask test failed"
    }
}
catch {
    Write-Host "[X] Flask verification failed" -ForegroundColor Red
    $allSuccess = $false
}

# Verify requests
Write-Host "[i] Verifying requests..." -ForegroundColor Cyan
try {
    $reqTest = & $PYTHON_EXE -c "import requests; print(requests.__version__)" 2>&1
    Write-Host "[OK] requests version: $reqTest" -ForegroundColor Green
}
catch {
    Write-Host "[X] requests verification failed" -ForegroundColor Red
    $allSuccess = $false
}

# Verify Pillow
Write-Host "[i] Verifying Pillow..." -ForegroundColor Cyan
try {
    $pilTest = & $PYTHON_EXE -c "from PIL import Image; print('OK')" 2>&1
    if ($pilTest -match "OK") {
        Write-Host "[OK] Pillow is available" -ForegroundColor Green
    }
    else {
        throw "Pillow test failed"
    }
}
catch {
    Write-Host "[X] Pillow verification failed" -ForegroundColor Red
    $allSuccess = $false
}

# Summary
Write-Host ""
if ($allSuccess) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Python Packages Setup Complete!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Installed packages:" -ForegroundColor Cyan
    foreach ($package in $PACKAGES) {
        Write-Host "    - $package" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  Next step: Run install_npm_packages.ps1" -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  Some packages failed to install!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please check errors above and try again." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

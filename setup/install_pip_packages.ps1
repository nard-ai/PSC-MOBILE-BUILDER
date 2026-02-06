# ============================================================================
# PSC Mobile Builder - Install Python Packages
# ============================================================================
# This script installs required Python packages to the portable Python
# Prerequisites: Run download_python.ps1 first
# ============================================================================

$ErrorActionPreference = "Stop"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$PYTHON_DIR = Join-Path $RUNTIME_DIR "python"
$PYTHON_EXE = Join-Path $PYTHON_DIR "python.exe"

# Required packages
$PACKAGES = @(
    "requests",
    "pillow"
)

# Colors for output
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Python Packages" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Python exists
if (-not (Test-Path $PYTHON_EXE)) {
    Write-Error "Python not found at: $PYTHON_EXE"
    Write-Host ""
    Write-Host "Please run download_python.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Verify Python works
Write-Info "Checking Python installation..."
$pythonVersion = & $PYTHON_EXE --version 2>&1
Write-Success "Found Python: $pythonVersion"

# Upgrade pip
Write-Info "Upgrading pip..."
try {
    & $PYTHON_EXE -m pip install --upgrade pip --quiet
    Write-Success "pip upgraded successfully"
}
catch {
    Write-Warning "Could not upgrade pip (may already be latest)"
}

# Install packages
Write-Host ""
Write-Info "Installing required packages..."
Write-Host ""

$allSuccess = $true

foreach ($package in $PACKAGES) {
    Write-Info "Installing $package..."
    try {
        & $PYTHON_EXE -m pip install $package --quiet
        
        # Verify installation
        $testResult = & $PYTHON_EXE -c "import $package; print('OK')" 2>&1
        if ($testResult -match "OK") {
            Write-Success "$package installed successfully"
        }
        else {
            throw "Import test failed"
        }
    }
    catch {
        Write-Error "Failed to install $package: $_"
        $allSuccess = $false
    }
}

# Test tkinter (should be included in WinPython)
Write-Host ""
Write-Info "Verifying tkinter (pre-installed with WinPython)..."
try {
    $tkTest = & $PYTHON_EXE -c "import tkinter; print('OK')" 2>&1
    if ($tkTest -match "OK") {
        Write-Success "tkinter is available"
    }
    else {
        throw "tkinter not available"
    }
}
catch {
    Write-Error "tkinter is not available. GUI will not work."
    Write-Host ""
    Write-Host "This should not happen with WinPython." -ForegroundColor Yellow
    Write-Host "Please verify WinPython was downloaded correctly." -ForegroundColor Yellow
    $allSuccess = $false
}

# Test PIL (pillow)
Write-Info "Verifying Pillow (PIL)..."
try {
    $pilTest = & $PYTHON_EXE -c "from PIL import Image; print('OK')" 2>&1
    if ($pilTest -match "OK") {
        Write-Success "Pillow (PIL) is available"
    }
    else {
        throw "Pillow not available"
    }
}
catch {
    Write-Error "Pillow is not available: $_"
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
        Write-Host "    - $package" -ForegroundColor Cyan
    }
    Write-Host "    - tkinter (pre-installed)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Next step: Run download_node.ps1 (if not done)" -ForegroundColor Yellow
    Write-Host "             or install_npm_packages.ps1" -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  Some packages failed to install!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please check the errors above and try again." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

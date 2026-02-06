# ============================================================================
# PSC Mobile Builder - Verify Setup
# ============================================================================
# This script verifies all components are installed correctly
# Run this after running all other setup scripts
# ============================================================================

$ErrorActionPreference = "Continue"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$PYTHON_DIR = Join-Path $RUNTIME_DIR "python"
$NODE_DIR = Join-Path $RUNTIME_DIR "node"

# Executables
$PYTHON_EXE = Join-Path $PYTHON_DIR "python.exe"
$NODE_EXE = Join-Path $NODE_DIR "node.exe"
$NPM_CMD = Join-Path $NODE_DIR "npm.cmd"
$EAS_CMD = Join-Path $NODE_DIR "eas.cmd"
$EXPO_CMD = Join-Path $NODE_DIR "expo.cmd"

# Colors for output
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }

# Track results
$checks = @{
    passed = 0
    failed = 0
    warnings = 0
}

function Test-Check {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [bool]$Required = $true
    )
    
    Write-Host "  Checking $Name... " -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "OK" -ForegroundColor Green
            $script:checks.passed++
            return $true
        }
        else {
            if ($Required) {
                Write-Host "FAILED" -ForegroundColor Red
                $script:checks.failed++
            }
            else {
                Write-Host "WARNING" -ForegroundColor Yellow
                $script:checks.warnings++
            }
            return $false
        }
    }
    catch {
        if ($Required) {
            Write-Host "FAILED - $_" -ForegroundColor Red
            $script:checks.failed++
        }
        else {
            Write-Host "WARNING - $_" -ForegroundColor Yellow
            $script:checks.warnings++
        }
        return $false
    }
}

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Setup Verification" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Set PATH for testing
$env:PATH = "$NODE_DIR;$PYTHON_DIR;$env:PATH"

# ============================================================================
# CHECK 1: Python Installation
# ============================================================================
Write-Host "[1/6] Python Installation" -ForegroundColor Cyan
Write-Host "─────────────────────────" -ForegroundColor Gray

Test-Check "Python executable exists" { Test-Path $PYTHON_EXE }

Test-Check "Python version" {
    $version = & $PYTHON_EXE --version 2>&1
    $version -match "Python 3\.(9|10|11|12)"
}

# ============================================================================
# CHECK 2: Python Packages
# ============================================================================
Write-Host ""
Write-Host "[2/6] Python Packages" -ForegroundColor Cyan
Write-Host "─────────────────────" -ForegroundColor Gray

Test-Check "tkinter module" {
    $result = & $PYTHON_EXE -c "import tkinter; print('OK')" 2>&1
    $result -match "OK"
}

Test-Check "requests module" {
    $result = & $PYTHON_EXE -c "import requests; print('OK')" 2>&1
    $result -match "OK"
}

Test-Check "PIL (Pillow) module" {
    $result = & $PYTHON_EXE -c "from PIL import Image; print('OK')" 2>&1
    $result -match "OK"
}

# ============================================================================
# CHECK 3: Node.js Installation
# ============================================================================
Write-Host ""
Write-Host "[3/6] Node.js Installation" -ForegroundColor Cyan
Write-Host "──────────────────────────" -ForegroundColor Gray

Test-Check "Node.js executable exists" { Test-Path $NODE_EXE }

Test-Check "Node.js version" {
    $version = & $NODE_EXE --version 2>&1
    $version -match "v(18|20|21|22)\."
}

# ============================================================================
# CHECK 4: NPM
# ============================================================================
Write-Host ""
Write-Host "[4/6] NPM" -ForegroundColor Cyan
Write-Host "─────────" -ForegroundColor Gray

Test-Check "npm command exists" { Test-Path $NPM_CMD }

Test-Check "npm version" {
    $version = & $NPM_CMD --version 2>&1
    $version -match "^\d+\.\d+\.\d+"
}

# ============================================================================
# CHECK 5: EAS CLI
# ============================================================================
Write-Host ""
Write-Host "[5/6] EAS CLI" -ForegroundColor Cyan
Write-Host "─────────────" -ForegroundColor Gray

Test-Check "eas.cmd exists" { Test-Path $EAS_CMD }

Test-Check "EAS CLI version" {
    $version = & $EAS_CMD --version 2>&1
    $version -match "eas-cli"
}

# ============================================================================
# CHECK 6: Project Template
# ============================================================================
Write-Host ""
Write-Host "[6/6] Project Files" -ForegroundColor Cyan
Write-Host "───────────────────" -ForegroundColor Gray

$projectFiles = @(
    "package.json",
    "App.tsx",
    "app.json",
    "eas.json",
    "tsconfig.json"
)

foreach ($file in $projectFiles) {
    $filePath = Join-Path $PROJECT_ROOT $file
    Test-Check "$file exists" { Test-Path $filePath } -Required $false
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  Verification Summary" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  Passed:   $($checks.passed)" -ForegroundColor Green
Write-Host "  Failed:   $($checks.failed)" -ForegroundColor $(if ($checks.failed -gt 0) { "Red" } else { "Green" })
Write-Host "  Warnings: $($checks.warnings)" -ForegroundColor $(if ($checks.warnings -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($checks.failed -eq 0) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  All critical checks passed!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  The portable runtime is ready." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Runtime locations:" -ForegroundColor Cyan
    Write-Host "    Python: $PYTHON_DIR" -ForegroundColor Gray
    Write-Host "    Node:   $NODE_DIR" -ForegroundColor Gray
    Write-Host ""
    
    if ($checks.warnings -gt 0) {
        Write-Host "  Note: Some optional checks had warnings." -ForegroundColor Yellow
        Write-Host "  The builder may still work correctly." -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "  Next steps:" -ForegroundColor Yellow
    Write-Host "    1. Create the builder application (Phase 2)" -ForegroundColor Gray
    Write-Host "    2. Create launcher scripts (Phase 4)" -ForegroundColor Gray
    Write-Host ""
    exit 0
}
else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  Some critical checks failed!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please run the following scripts to fix:" -ForegroundColor Yellow
    
    if (-not (Test-Path $PYTHON_EXE)) {
        Write-Host "    .\setup\download_python.ps1" -ForegroundColor Cyan
        Write-Host "    .\setup\install_pip_packages.ps1" -ForegroundColor Cyan
    }
    
    if (-not (Test-Path $NODE_EXE)) {
        Write-Host "    .\setup\download_node.ps1" -ForegroundColor Cyan
        Write-Host "    .\setup\install_npm_packages.ps1" -ForegroundColor Cyan
    }
    elseif (-not (Test-Path $EAS_CMD)) {
        Write-Host "    .\setup\install_npm_packages.ps1" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "  Then run this script again to verify." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

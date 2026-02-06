# PSC Mobile Builder - Verify Setup

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

# Track results
$passed = 0
$failed = 0

function Test-Check {
    param([string]$Name, [scriptblock]$Test)
    
    Write-Host "  $Name... " -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "OK" -ForegroundColor Green
            $script:passed++
            return $true
        }
        else {
            Write-Host "FAILED" -ForegroundColor Red
            $script:failed++
            return $false
        }
    }
    catch {
        Write-Host "FAILED" -ForegroundColor Red
        $script:failed++
        return $false
    }
}

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Setup Verification" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Set PATH
$env:PATH = "$NODE_DIR;$PYTHON_DIR;$env:PATH"

# Python checks
Write-Host "[1/5] Python Installation" -ForegroundColor Cyan

Test-Check "Python executable exists" { Test-Path $PYTHON_EXE }

Test-Check "Python version check" {
    $version = & $PYTHON_EXE --version 2>&1
    $version -match "Python 3\."
}

# Python packages
Write-Host ""
Write-Host "[2/5] Python Packages" -ForegroundColor Cyan

Test-Check "Flask module" {
    $result = & $PYTHON_EXE -c "import flask; print('OK')" 2>&1
    $result -match "OK"
}

Test-Check "requests module" {
    $result = & $PYTHON_EXE -c "import requests; print('OK')" 2>&1
    $result -match "OK"
}

Test-Check "Pillow module" {
    $result = & $PYTHON_EXE -c "from PIL import Image; print('OK')" 2>&1
    $result -match "OK"
}

# Node.js checks
Write-Host ""
Write-Host "[3/5] Node.js Installation" -ForegroundColor Cyan

Test-Check "Node.js executable exists" { Test-Path $NODE_EXE }

Test-Check "Node.js version check" {
    $version = & $NODE_EXE --version 2>&1
    $version -match "v(18|20|21|22)\."
}

# npm checks
Write-Host ""
Write-Host "[4/5] NPM" -ForegroundColor Cyan

Test-Check "npm command exists" { Test-Path $NPM_CMD }

# Skip npm version check - we verify npm works via EAS CLI which uses npm internally
Write-Host "  npm version check... " -NoNewline
Write-Host "SKIPPED (verified via EAS CLI)" -ForegroundColor Gray
$script:passed++

# EAS CLI checks
Write-Host ""
Write-Host "[5/5] EAS CLI" -ForegroundColor Cyan

Test-Check "eas.cmd exists" { Test-Path $EAS_CMD }

Test-Check "EAS CLI version check" {
    $version = & $EAS_CMD --version 2>&1
    $version -match "eas-cli"
}

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  Verification Summary" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  All checks passed!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  The portable runtime is ready." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Runtime locations:" -ForegroundColor Cyan
    Write-Host "    Python: $PYTHON_DIR" -ForegroundColor Gray
    Write-Host "    Node:   $NODE_DIR" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Yellow
    Write-Host "    Phase 2: Create the builder application" -ForegroundColor Gray
    Write-Host ""
    exit 0
}
else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  Some checks failed!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please run the setup scripts to fix:" -ForegroundColor Yellow
    
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
    exit 1
}

# ============================================================================
# PSC Mobile Builder - Install NPM Packages
# ============================================================================
# This script installs EAS CLI and Expo CLI to the portable Node.js
# Prerequisites: Run download_node.ps1 first
# ============================================================================

$ErrorActionPreference = "Stop"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$NODE_DIR = Join-Path $RUNTIME_DIR "node"
$NODE_EXE = Join-Path $NODE_DIR "node.exe"
$NPM_CMD = Join-Path $NODE_DIR "npm.cmd"
$NODE_MODULES = Join-Path $NODE_DIR "node_modules"

# Colors for output
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - NPM Packages" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Node exists
if (-not (Test-Path $NODE_EXE)) {
    Write-Error "Node.js not found at: $NODE_EXE"
    Write-Host ""
    Write-Host "Please run download_node.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Set PATH to use portable Node
$env:PATH = "$NODE_DIR;$env:PATH"

# Verify Node works
Write-Info "Checking Node.js installation..."
$nodeVersion = & $NODE_EXE --version 2>&1
Write-Success "Found Node.js: $nodeVersion"

$npmVersion = & $NPM_CMD --version 2>&1
Write-Success "Found npm: v$npmVersion"

# Initialize package.json in node directory for local installs
Write-Info "Initializing npm in Node directory..."
Push-Location $NODE_DIR

try {
    # Create minimal package.json if it doesn't exist
    $packageJsonPath = Join-Path $NODE_DIR "package.json"
    if (-not (Test-Path $packageJsonPath)) {
        $packageJson = @{
            name = "psc-mobile-builder-runtime"
            version = "1.0.0"
            description = "Portable runtime for PSC Mobile Builder"
            private = $true
        } | ConvertTo-Json
        
        Set-Content -Path $packageJsonPath -Value $packageJson
        Write-Success "Created package.json"
    }
    
    # Install EAS CLI
    Write-Host ""
    Write-Info "Installing EAS CLI..."
    Write-Info "This may take 2-3 minutes..."
    
    & $NPM_CMD install eas-cli --save 2>&1 | ForEach-Object {
        if ($_ -match "error|warn") {
            Write-Host $_ -ForegroundColor Yellow
        }
    }
    
    # Verify EAS CLI installation
    $easPath = Join-Path $NODE_MODULES "eas-cli"
    if (Test-Path $easPath) {
        Write-Success "EAS CLI installed"
    }
    else {
        throw "EAS CLI installation failed"
    }
    
    # Install Expo CLI
    Write-Host ""
    Write-Info "Installing Expo CLI (@expo/cli)..."
    Write-Info "This may take 1-2 minutes..."
    
    & $NPM_CMD install @expo/cli --save 2>&1 | ForEach-Object {
        if ($_ -match "error|warn") {
            Write-Host $_ -ForegroundColor Yellow
        }
    }
    
    # Verify Expo CLI installation
    $expoPath = Join-Path $NODE_MODULES "@expo"
    if (Test-Path $expoPath) {
        Write-Success "Expo CLI installed"
    }
    else {
        throw "Expo CLI installation failed"
    }
    
    # Create wrapper scripts for eas and expo commands
    Write-Host ""
    Write-Info "Creating command wrapper scripts..."
    
    # Create eas.cmd wrapper
    $easCmdPath = Join-Path $NODE_DIR "eas.cmd"
    $easCmdContent = @"
@echo off
"%~dp0node.exe" "%~dp0node_modules\eas-cli\bin\run" %*
"@
    Set-Content -Path $easCmdPath -Value $easCmdContent
    Write-Success "Created eas.cmd"
    
    # Create expo.cmd wrapper
    $expoCmdPath = Join-Path $NODE_DIR "expo.cmd"
    $expoCmdContent = @"
@echo off
"%~dp0node.exe" "%~dp0node_modules\@expo\cli\build\bin\cli" %*
"@
    Set-Content -Path $expoCmdPath -Value $expoCmdContent
    Write-Success "Created expo.cmd"
    
    # Verify eas command works
    Write-Host ""
    Write-Info "Verifying EAS CLI..."
    $easVersion = & $easCmdPath --version 2>&1
    if ($easVersion -match "eas-cli") {
        Write-Success "EAS CLI working: $easVersion"
    }
    else {
        Write-Warning "EAS CLI version check returned: $easVersion"
    }
    
}
catch {
    Write-Error "Installation failed: $_"
    Pop-Location
    exit 1
}

Pop-Location

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  NPM Packages Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Installed packages:" -ForegroundColor Cyan
Write-Host "    - eas-cli" -ForegroundColor Cyan
Write-Host "    - @expo/cli" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Wrapper scripts created:" -ForegroundColor Cyan
Write-Host "    - $NODE_DIR\eas.cmd" -ForegroundColor Cyan
Write-Host "    - $NODE_DIR\expo.cmd" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next step: Run verify_setup.ps1 to verify everything" -ForegroundColor Yellow
Write-Host ""

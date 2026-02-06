# PSC Mobile Builder - Install NPM Packages

# Don't stop on npm warnings (they go to stderr)
$ErrorActionPreference = "Continue"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$NODE_DIR = Join-Path $RUNTIME_DIR "node"
$NODE_EXE = Join-Path $NODE_DIR "node.exe"
$NPM_CMD = Join-Path $NODE_DIR "npm.cmd"
$NODE_MODULES = Join-Path $NODE_DIR "node_modules"

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - NPM Packages" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Node exists
if (-not (Test-Path $NODE_EXE)) {
    Write-Host "[X] Node.js not found at: $NODE_EXE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run download_node.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Set PATH to use portable Node
$env:PATH = "$NODE_DIR;$env:PATH"

# Verify Node works
Write-Host "[i] Checking Node.js installation..." -ForegroundColor Cyan
$nodeVersion = & $NODE_EXE --version 2>&1
Write-Host "[OK] Found Node.js: $nodeVersion" -ForegroundColor Green

$npmVersion = & $NPM_CMD --version 2>&1
Write-Host "[OK] Found npm: v$npmVersion" -ForegroundColor Green

# Navigate to Node directory for local install
Push-Location $NODE_DIR

try {
    # Create package.json if not exists
    $packageJsonPath = Join-Path $NODE_DIR "package.json"
    if (-not (Test-Path $packageJsonPath)) {
        Write-Host "[i] Creating package.json..." -ForegroundColor Cyan
        $packageJson = @"
{
  "name": "psc-mobile-builder-runtime",
  "version": "1.0.0",
  "description": "Portable runtime for PSC Mobile Builder",
  "private": true
}
"@
        Set-Content -Path $packageJsonPath -Value $packageJson
        Write-Host "[OK] Created package.json" -ForegroundColor Green
    }
    
    # Install EAS CLI
    Write-Host ""
    Write-Host "[i] Installing EAS CLI (this may take 2-3 minutes)..." -ForegroundColor Cyan
    
    $npmOutput = & $NPM_CMD install eas-cli --save 2>&1
    # npm warnings are normal, only check if the package was installed
    
    # Verify EAS CLI
    $easPath = Join-Path $NODE_MODULES "eas-cli"
    if (Test-Path $easPath) {
        Write-Host "[OK] EAS CLI installed" -ForegroundColor Green
    }
    else {
        Write-Host "[X] EAS CLI installation failed" -ForegroundColor Red
        Write-Host "npm output: $npmOutput" -ForegroundColor Gray
        throw "EAS CLI installation failed"
    }
    
    # Install Expo CLI
    Write-Host ""
    Write-Host "[i] Installing Expo CLI (this may take 1-2 minutes)..." -ForegroundColor Cyan
    
    $npmOutput = & $NPM_CMD install @expo/cli --save 2>&1
    # npm warnings are normal, only check if the package was installed
    
    # Verify Expo CLI
    $expoPath = Join-Path $NODE_MODULES "@expo"
    if (Test-Path $expoPath) {
        Write-Host "[OK] Expo CLI installed" -ForegroundColor Green
    }
    else {
        Write-Host "[X] Expo CLI installation failed" -ForegroundColor Red
        throw "Expo CLI installation failed"
    }
    
    # Create eas.cmd wrapper
    Write-Host ""
    Write-Host "[i] Creating command wrappers..." -ForegroundColor Cyan
    
    $easCmdPath = Join-Path $NODE_DIR "eas.cmd"
    $easCmdContent = "@echo off`r`n`"%~dp0node.exe`" `"%~dp0node_modules\eas-cli\bin\run`" %*"
    Set-Content -Path $easCmdPath -Value $easCmdContent -NoNewline
    Write-Host "[OK] Created eas.cmd" -ForegroundColor Green
    
    # Create expo.cmd wrapper
    $expoCmdPath = Join-Path $NODE_DIR "expo.cmd"
    $expoCmdContent = "@echo off`r`n`"%~dp0node.exe`" `"%~dp0node_modules\@expo\cli\build\bin\cli`" %*"
    Set-Content -Path $expoCmdPath -Value $expoCmdContent -NoNewline
    Write-Host "[OK] Created expo.cmd" -ForegroundColor Green
    
    # Verify eas command
    Write-Host ""
    Write-Host "[i] Verifying EAS CLI..." -ForegroundColor Cyan
    $easVersion = & $easCmdPath --version 2>&1
    Write-Host "[OK] EAS CLI working: $easVersion" -ForegroundColor Green
    
}
catch {
    Write-Host "[X] Installation failed: $_" -ForegroundColor Red
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
Write-Host "    - eas-cli" -ForegroundColor Gray
Write-Host "    - @expo/cli" -ForegroundColor Gray
Write-Host ""
Write-Host "  Wrapper scripts created:" -ForegroundColor Cyan
Write-Host "    - eas.cmd" -ForegroundColor Gray
Write-Host "    - expo.cmd" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next step: Run verify_setup.ps1" -ForegroundColor Yellow
Write-Host ""

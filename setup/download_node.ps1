# PSC Mobile Builder - Download Node.js Portable

$ErrorActionPreference = "Stop"

# Configuration
$NODE_VERSION = "20.11.0"
$NODE_URL = "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-win-x64.zip"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$NODE_DIR = Join-Path $RUNTIME_DIR "node"
$TEMP_DIR = Join-Path $PROJECT_ROOT "temp"
$DOWNLOAD_FILE = Join-Path $TEMP_DIR "node.zip"

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Node.js Setup" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Node already exists
if (Test-Path $NODE_DIR) {
    Write-Host "[!] Node.js directory already exists at: $NODE_DIR" -ForegroundColor Yellow
    $response = Read-Host "Do you want to re-download? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "[i] Skipping Node.js download." -ForegroundColor Cyan
        exit 0
    }
    Write-Host "[i] Removing existing Node.js directory..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force $NODE_DIR
}

# Create directories
Write-Host "[i] Creating directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $RUNTIME_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Download Node.js
Write-Host "[i] Downloading Node.js v$NODE_VERSION (~30 MB)..." -ForegroundColor Cyan
Write-Host "[i] URL: $NODE_URL" -ForegroundColor Gray
Write-Host ""

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $NODE_URL -OutFile $DOWNLOAD_FILE -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    if (Test-Path $DOWNLOAD_FILE) {
        $fileInfo = Get-Item $DOWNLOAD_FILE
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        Write-Host "[OK] Downloaded successfully ($fileSizeMB MB)" -ForegroundColor Green
    }
    else {
        throw "Download file not found"
    }
}
catch {
    Write-Host "[X] Failed to download Node.js: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually from:" -ForegroundColor Yellow
    Write-Host "  https://nodejs.org/en/download/" -ForegroundColor Cyan
    exit 1
}

# Extract Node.js
Write-Host "[i] Extracting Node.js..." -ForegroundColor Cyan

try {
    $extractDir = Join-Path $TEMP_DIR "node_extracted"
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    
    Expand-Archive -Path $DOWNLOAD_FILE -DestinationPath $extractDir -Force
    
    $extractedFolder = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    
    if ($null -eq $extractedFolder) {
        throw "Could not find extracted Node.js folder"
    }
    
    Write-Host "[i] Found Node.js at: $($extractedFolder.FullName)" -ForegroundColor Cyan
    
    Move-Item -Path $extractedFolder.FullName -Destination $NODE_DIR -Force
    
    Write-Host "[OK] Node.js installed to: $NODE_DIR" -ForegroundColor Green
}
catch {
    Write-Host "[X] Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# Verify installation
Write-Host "[i] Verifying Node.js installation..." -ForegroundColor Cyan

$nodeExe = Join-Path $NODE_DIR "node.exe"
$npmCmd = Join-Path $NODE_DIR "npm.cmd"

if (Test-Path $nodeExe) {
    $nodeVersion = & $nodeExe --version 2>&1
    Write-Host "[OK] Node.js installed: $nodeVersion" -ForegroundColor Green
}
else {
    Write-Host "[X] Node.js executable not found at: $nodeExe" -ForegroundColor Red
    exit 1
}

if (Test-Path $npmCmd) {
    $env:PATH = "$NODE_DIR;$env:PATH"
    $npmVersion = & $npmCmd --version 2>&1
    Write-Host "[OK] npm installed: v$npmVersion" -ForegroundColor Green
}
else {
    Write-Host "[X] npm not found at: $npmCmd" -ForegroundColor Red
    exit 1
}

# Cleanup
Write-Host "[i] Cleaning up temporary files..." -ForegroundColor Cyan
if (Test-Path $TEMP_DIR) {
    Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue
}
Write-Host "[OK] Cleanup complete" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Node.js Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Location: $NODE_DIR" -ForegroundColor Cyan
Write-Host "  Node: $nodeVersion" -ForegroundColor Cyan
Write-Host "  npm: v$npmVersion" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next step: Run install_npm_packages.ps1" -ForegroundColor Yellow
Write-Host ""

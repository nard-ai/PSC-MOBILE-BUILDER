# ============================================================================
# PSC Mobile Builder - Download Node.js Portable
# ============================================================================
# This script downloads Node.js portable (official binary distribution)
# Run this script from the project root directory
# ============================================================================

$ErrorActionPreference = "Stop"

# Configuration
$NODE_VERSION = "20.11.0"
$NODE_URL = "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-win-x64.zip"
$ALTERNATIVE_URL = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$NODE_DIR = Join-Path $RUNTIME_DIR "node"
$TEMP_DIR = Join-Path $PROJECT_ROOT "temp"
$DOWNLOAD_FILE = Join-Path $TEMP_DIR "node.zip"

# Colors for output
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Node.js Setup" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Node already exists
if (Test-Path $NODE_DIR) {
    Write-Warning "Node.js directory already exists at: $NODE_DIR"
    $response = Read-Host "Do you want to re-download? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Info "Skipping Node.js download."
        exit 0
    }
    Write-Info "Removing existing Node.js directory..."
    Remove-Item -Recurse -Force $NODE_DIR
}

# Create directories
Write-Info "Creating directories..."
New-Item -ItemType Directory -Path $RUNTIME_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Download Node.js
Write-Info "Downloading Node.js v$NODE_VERSION..."
Write-Info "This may take a few minutes (~30 MB)..."
Write-Host ""

$downloadSuccess = $false
$urls = @($NODE_URL, $ALTERNATIVE_URL)

foreach ($url in $urls) {
    try {
        Write-Info "Trying: $url"
        
        # Download with progress indicator
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $DOWNLOAD_FILE -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        if (Test-Path $DOWNLOAD_FILE) {
            $fileSize = (Get-Item $DOWNLOAD_FILE).Length / 1MB
            Write-Success "Downloaded successfully ($([math]::Round($fileSize, 2)) MB)"
            $downloadSuccess = $true
            break
        }
    }
    catch {
        Write-Warning "Failed to download from this URL. Trying alternative..."
    }
}

if (-not $downloadSuccess) {
    Write-Error "Failed to download Node.js from all sources."
    Write-Host ""
    Write-Host "Please download manually from:" -ForegroundColor Yellow
    Write-Host "  https://nodejs.org/en/download/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Download: node-v20.x.x-win-x64.zip" -ForegroundColor Yellow
    Write-Host "And extract it to: $NODE_DIR" -ForegroundColor Yellow
    exit 1
}

# Extract Node.js
Write-Info "Extracting Node.js..."

try {
    # Create extraction directory
    $extractDir = Join-Path $TEMP_DIR "node_extracted"
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    
    # Extract ZIP
    Expand-Archive -Path $DOWNLOAD_FILE -DestinationPath $extractDir -Force
    
    # Find the extracted folder (node-v20.x.x-win-x64)
    $extractedFolder = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    
    if ($null -eq $extractedFolder) {
        throw "Could not find extracted Node.js folder"
    }
    
    Write-Info "Found Node.js at: $($extractedFolder.FullName)"
    
    # Move to runtime/node
    Write-Info "Moving Node.js to final location..."
    Move-Item -Path $extractedFolder.FullName -Destination $NODE_DIR -Force
    
    Write-Success "Node.js installed to: $NODE_DIR"
}
catch {
    Write-Error "Extraction failed: $_"
    exit 1
}

# Verify installation
Write-Info "Verifying Node.js installation..."

$nodeExe = Join-Path $NODE_DIR "node.exe"
$npmCmd = Join-Path $NODE_DIR "npm.cmd"

if (Test-Path $nodeExe) {
    $nodeVersion = & $nodeExe --version 2>&1
    Write-Success "Node.js installed: $nodeVersion"
}
else {
    Write-Error "Node.js executable not found at: $nodeExe"
    exit 1
}

if (Test-Path $npmCmd) {
    # Set PATH temporarily to test npm
    $env:PATH = "$NODE_DIR;$env:PATH"
    $npmVersion = & $npmCmd --version 2>&1
    Write-Success "npm installed: v$npmVersion"
}
else {
    Write-Error "npm not found at: $npmCmd"
    exit 1
}

# Cleanup
Write-Info "Cleaning up temporary files..."
if (Test-Path $TEMP_DIR) {
    Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue
}
Write-Success "Cleanup complete"

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Node.js Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Location: $NODE_DIR" -ForegroundColor Cyan
Write-Host "  Node:     $nodeVersion" -ForegroundColor Cyan
Write-Host "  npm:      v$npmVersion" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next step: Run install_npm_packages.ps1" -ForegroundColor Yellow
Write-Host ""

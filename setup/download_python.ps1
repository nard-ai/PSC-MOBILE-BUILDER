# ============================================================================
# PSC Mobile Builder - Download Python Portable
# ============================================================================
# This script downloads WinPython (portable Python with tkinter included)
# Run this script from the project root directory
# ============================================================================

$ErrorActionPreference = "Stop"

# Configuration
$PYTHON_VERSION = "3.11.8.0"
$WINPYTHON_URL = "https://github.com/winpython/winpython/releases/download/8.1.20240206final/Winpython64-3.11.8.0dot.exe"
$ALTERNATIVE_URL = "https://github.com/winpython/winpython/releases/download/7.1.20240203final/Winpython64-3.11.8.0dot.exe"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$PYTHON_DIR = Join-Path $RUNTIME_DIR "python"
$TEMP_DIR = Join-Path $PROJECT_ROOT "temp"
$DOWNLOAD_FILE = Join-Path $TEMP_DIR "winpython.exe"

# Colors for output
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Python Setup" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Python already exists
if (Test-Path $PYTHON_DIR) {
    Write-Warning "Python directory already exists at: $PYTHON_DIR"
    $response = Read-Host "Do you want to re-download? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Info "Skipping Python download."
        exit 0
    }
    Write-Info "Removing existing Python directory..."
    Remove-Item -Recurse -Force $PYTHON_DIR
}

# Create directories
Write-Info "Creating directories..."
New-Item -ItemType Directory -Path $RUNTIME_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Download WinPython
Write-Info "Downloading WinPython $PYTHON_VERSION..."
Write-Info "This may take a few minutes (~100 MB)..."
Write-Host ""

$downloadSuccess = $false
$urls = @($WINPYTHON_URL, $ALTERNATIVE_URL)

foreach ($url in $urls) {
    try {
        Write-Info "Trying: $url"
        
        # Use BITS for faster download with progress
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
    Write-Error "Failed to download WinPython from all sources."
    Write-Host ""
    Write-Host "Please download manually from:" -ForegroundColor Yellow
    Write-Host "  https://github.com/winpython/winpython/releases" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Download the file: Winpython64-3.11.x.x.dot.exe" -ForegroundColor Yellow
    Write-Host "And extract it to: $PYTHON_DIR" -ForegroundColor Yellow
    exit 1
}

# Extract WinPython
Write-Info "Extracting WinPython (this may take a minute)..."
Write-Info "Extraction path: $RUNTIME_DIR"

try {
    # WinPython .exe is a self-extracting 7z archive
    # We can use 7z to extract it, or run it silently
    
    # Method 1: Try to run the self-extractor silently
    $extractProcess = Start-Process -FilePath $DOWNLOAD_FILE -ArgumentList "-y", "-o`"$TEMP_DIR\winpython_extracted`"" -Wait -PassThru -NoNewWindow
    
    if ($extractProcess.ExitCode -eq 0) {
        Write-Success "Extraction completed"
    }
    else {
        throw "Extraction failed with exit code: $($extractProcess.ExitCode)"
    }
    
    # Find the extracted Python folder
    $extractedFolder = Get-ChildItem -Path "$TEMP_DIR\winpython_extracted" -Directory | Select-Object -First 1
    
    if ($null -eq $extractedFolder) {
        throw "Could not find extracted WinPython folder"
    }
    
    # Find python folder inside WinPython
    $pythonSubFolder = Get-ChildItem -Path $extractedFolder.FullName -Directory -Filter "python-*" | Select-Object -First 1
    
    if ($null -eq $pythonSubFolder) {
        # Try alternative structure
        $pythonSubFolder = Get-ChildItem -Path $extractedFolder.FullName -Directory | Where-Object { Test-Path (Join-Path $_.FullName "python.exe") } | Select-Object -First 1
    }
    
    if ($null -eq $pythonSubFolder) {
        # Last resort: use the main folder if python.exe is there
        if (Test-Path (Join-Path $extractedFolder.FullName "python.exe")) {
            $pythonSubFolder = $extractedFolder
        }
        else {
            throw "Could not find Python executable in extracted folder"
        }
    }
    
    Write-Info "Found Python at: $($pythonSubFolder.FullName)"
    
    # Move Python folder to runtime/python
    Write-Info "Moving Python to final location..."
    Move-Item -Path $pythonSubFolder.FullName -Destination $PYTHON_DIR -Force
    
    Write-Success "Python installed to: $PYTHON_DIR"
}
catch {
    Write-Error "Extraction failed: $_"
    Write-Host ""
    Write-Host "Alternative: Extract the downloaded file manually" -ForegroundColor Yellow
    Write-Host "1. Run: $DOWNLOAD_FILE" -ForegroundColor Cyan
    Write-Host "2. Extract to: $TEMP_DIR" -ForegroundColor Cyan
    Write-Host "3. Move the python-3.x.x folder to: $PYTHON_DIR" -ForegroundColor Cyan
    exit 1
}

# Verify installation
Write-Info "Verifying Python installation..."

$pythonExe = Join-Path $PYTHON_DIR "python.exe"

if (Test-Path $pythonExe) {
    $version = & $pythonExe --version 2>&1
    Write-Success "Python installed: $version"
    
    # Test tkinter
    Write-Info "Testing tkinter..."
    $tkTest = & $pythonExe -c "import tkinter; print('tkinter OK')" 2>&1
    if ($tkTest -match "OK") {
        Write-Success "tkinter is available"
    }
    else {
        Write-Warning "tkinter test failed. GUI may not work."
    }
}
else {
    Write-Error "Python executable not found at: $pythonExe"
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
Write-Host "  Python Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Location: $PYTHON_DIR" -ForegroundColor Cyan
Write-Host "  Version:  $version" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next step: Run install_pip_packages.ps1" -ForegroundColor Yellow
Write-Host ""

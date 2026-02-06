# PSC Mobile Builder - Download Python Portable

$ErrorActionPreference = "Stop"

# Configuration - Using Python Embedded + get-pip approach
$PYTHON_VERSION = "3.11.8"
$PYTHON_URL = "https://www.python.org/ftp/python/$PYTHON_VERSION/python-$PYTHON_VERSION-embed-amd64.zip"
$GET_PIP_URL = "https://bootstrap.pypa.io/get-pip.py"

# Paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$RUNTIME_DIR = Join-Path $PROJECT_ROOT "runtime"
$PYTHON_DIR = Join-Path $RUNTIME_DIR "python"
$TEMP_DIR = Join-Path $PROJECT_ROOT "temp"
$DOWNLOAD_FILE = Join-Path $TEMP_DIR "python.zip"

# Header
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PSC Mobile Builder - Python Setup" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if Python already exists
if (Test-Path $PYTHON_DIR) {
    Write-Host "[!] Python directory already exists at: $PYTHON_DIR" -ForegroundColor Yellow
    $response = Read-Host "Do you want to re-download? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "[i] Skipping Python download." -ForegroundColor Cyan
        exit 0
    }
    Write-Host "[i] Removing existing Python directory..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force $PYTHON_DIR
}

# Create directories
Write-Host "[i] Creating directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $RUNTIME_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $PYTHON_DIR -Force | Out-Null

# Download Python Embedded
Write-Host "[i] Downloading Python $PYTHON_VERSION Embedded (~15 MB)..." -ForegroundColor Cyan
Write-Host "[i] URL: $PYTHON_URL" -ForegroundColor Gray

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $PYTHON_URL -OutFile $DOWNLOAD_FILE -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    if (Test-Path $DOWNLOAD_FILE) {
        $fileInfo = Get-Item $DOWNLOAD_FILE
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        Write-Host "[OK] Downloaded Python ($fileSizeMB MB)" -ForegroundColor Green
    }
    else {
        throw "Download file not found"
    }
}
catch {
    Write-Host "[X] Failed to download Python: $_" -ForegroundColor Red
    exit 1
}

# Extract Python
Write-Host "[i] Extracting Python..." -ForegroundColor Cyan

try {
    Expand-Archive -Path $DOWNLOAD_FILE -DestinationPath $PYTHON_DIR -Force
    Write-Host "[OK] Python extracted to: $PYTHON_DIR" -ForegroundColor Green
}
catch {
    Write-Host "[X] Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# Enable pip in embedded Python (modify python311._pth)
Write-Host "[i] Configuring Python for pip..." -ForegroundColor Cyan

$pthFile = Join-Path $PYTHON_DIR "python311._pth"
if (Test-Path $pthFile) {
    # Read current content and uncomment import site
    $content = Get-Content $pthFile
    $newContent = $content -replace "#import site", "import site"
    # Add Lib\site-packages
    $newContent += "Lib\site-packages"
    Set-Content -Path $pthFile -Value $newContent
    Write-Host "[OK] Updated python311._pth" -ForegroundColor Green
}

# Download and run get-pip.py
Write-Host "[i] Downloading pip installer..." -ForegroundColor Cyan
$getPipFile = Join-Path $TEMP_DIR "get-pip.py"

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $GET_PIP_URL -OutFile $getPipFile -UseBasicParsing
    $ProgressPreference = 'Continue'
    Write-Host "[OK] Downloaded get-pip.py" -ForegroundColor Green
}
catch {
    Write-Host "[X] Failed to download get-pip.py: $_" -ForegroundColor Red
    exit 1
}

# Install pip
Write-Host "[i] Installing pip..." -ForegroundColor Cyan
$pythonExe = Join-Path $PYTHON_DIR "python.exe"

try {
    & $pythonExe $getPipFile --no-warn-script-location 2>&1 | Out-Null
    Write-Host "[OK] pip installed" -ForegroundColor Green
}
catch {
    Write-Host "[X] Failed to install pip: $_" -ForegroundColor Red
    exit 1
}

# Verify installation
Write-Host "[i] Verifying Python installation..." -ForegroundColor Cyan

if (Test-Path $pythonExe) {
    $version = & $pythonExe --version 2>&1
    Write-Host "[OK] Python installed: $version" -ForegroundColor Green
}
else {
    Write-Host "[X] Python executable not found" -ForegroundColor Red
    exit 1
}

# Check pip
$pipVersion = & $pythonExe -m pip --version 2>&1
if ($pipVersion -match "pip") {
    Write-Host "[OK] pip available: $pipVersion" -ForegroundColor Green
}
else {
    Write-Host "[!] pip may not be working correctly" -ForegroundColor Yellow
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
Write-Host "  Python Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Location: $PYTHON_DIR" -ForegroundColor Cyan
Write-Host "  Version: $version" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Note: This is Python Embedded (no tkinter)." -ForegroundColor Yellow
Write-Host "  We will use a web-based UI instead." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Next step: Run install_pip_packages.ps1" -ForegroundColor Yellow
Write-Host ""

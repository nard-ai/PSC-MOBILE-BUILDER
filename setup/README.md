# PSC Mobile Builder - Setup Scripts

These scripts are used to set up the portable runtime environment for the PSC Mobile Builder.

## Prerequisites

- Windows 10 or later
- PowerShell 5.1 or later (included with Windows 10)
- Internet connection (for downloading runtimes)

## Setup Order

Run these scripts in order from the project root directory:

```powershell
# Step 1: Download Python portable (~100 MB)
.\setup\download_python.ps1

# Step 2: Install Python packages
.\setup\install_pip_packages.ps1

# Step 3: Download Node.js portable (~30 MB)
.\setup\download_node.ps1

# Step 4: Install EAS CLI and Expo CLI (~100 MB)
.\setup\install_npm_packages.ps1

# Step 5: Verify everything is installed correctly
.\setup\verify_setup.ps1
```

## What Gets Installed

### runtime/python/ (~100 MB)

- WinPython 3.11.8 (portable Python with tkinter)
- requests (HTTP library)
- pillow (image processing)

### runtime/node/ (~170 MB with packages)

- Node.js v20.11.0 (LTS)
- npm
- eas-cli (Expo Application Services)
- @expo/cli (Expo CLI)

## Troubleshooting

### PowerShell Execution Policy Error

If you get an error about execution policy, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Download Fails

If automatic download fails, the script will show manual download URLs. Download the files manually and extract to the appropriate folders.

### "Not Recognized" Errors

Make sure you're running from the project root directory, not from inside the setup folder.

## Scripts Description

| Script                     | Purpose                             |
| -------------------------- | ----------------------------------- |
| `download_python.ps1`      | Downloads WinPython portable        |
| `download_node.ps1`        | Downloads Node.js portable          |
| `install_pip_packages.ps1` | Installs Python packages            |
| `install_npm_packages.ps1` | Installs EAS CLI and Expo CLI       |
| `verify_setup.ps1`         | Verifies all installations          |
| `create_package.ps1`       | Creates distributable ZIP (Phase 5) |

## After Setup

Once all scripts complete successfully, the runtime folder structure should be:

```
runtime/
├── python/
│   ├── python.exe
│   ├── pythonw.exe
│   ├── Lib/
│   │   └── site-packages/
│   │       ├── requests/
│   │       └── PIL/
│   └── ...
│
└── node/
    ├── node.exe
    ├── npm.cmd
    ├── npx.cmd
    ├── eas.cmd      (custom wrapper)
    ├── expo.cmd     (custom wrapper)
    ├── node_modules/
    │   ├── eas-cli/
    │   └── @expo/
    └── ...
```

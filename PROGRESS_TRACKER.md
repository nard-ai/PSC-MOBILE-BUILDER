# PSC Mobile Builder - Portable Installation Progress Tracker

## Project Overview
**Branch:** `Portable-Installation`  
**Goal:** Create a completely self-contained Mobile App Builder that requires zero installation on POS systems  
**Last Updated:** February 6, 2026

---

## Phase Summary

| Phase No. | Features | Description | Progress |
|-----------|----------|-------------|----------|
| Phase 1 | Setup Infrastructure | Download scripts for Python & Node.js portable runtimes | 🔄 In Progress |
| Phase 2 | Builder Application | Port Tkinter GUI to use portable runtimes | ⏳ Not Started |
| Phase 3 | Project Template | Configure React Native template for portable builds | ⏳ Not Started |
| Phase 4 | Launcher Scripts | Create START-BUILDER.bat and environment setup | ⏳ Not Started |
| Phase 5 | Packaging | Create final distributable ZIP package | ⏳ Not Started |
| Phase 6 | Documentation | README, troubleshooting guide, user instructions | ⏳ Not Started |

---

## Phase 1: Setup Infrastructure

**Status:** 🔄 In Progress  
**Description:** Create PowerShell scripts to download and configure portable Python and Node.js runtimes with all required dependencies.

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 1.1 | Create setup folder structure | Create `setup/` folder for all setup scripts | ⏳ Not Started |
| 1.2 | download_python.ps1 | Script to download WinPython portable (~100 MB) | ⏳ Not Started |
| 1.3 | download_node.ps1 | Script to download Node.js portable (~70 MB) | ⏳ Not Started |
| 1.4 | install_pip_packages.ps1 | Install requests, pillow to portable Python | ⏳ Not Started |
| 1.5 | install_npm_packages.ps1 | Install eas-cli, @expo/cli to portable Node | ⏳ Not Started |
| 1.6 | verify_setup.ps1 | Verify all components installed correctly | ⏳ Not Started |
| 1.7 | Test Phase 1 | Run all scripts, verify runtime/ folder created | ⏳ Not Started |

---

## Phase 2: Builder Application

**Status:** ⏳ Not Started  
**Description:** Create the Tkinter GUI application that uses portable runtimes instead of system-installed tools.

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 2.1 | Create builder folder structure | Create `builder/` folder with module structure | ⏳ Not Started |
| 2.2 | config.py | Configuration module (paths, settings, EXPO_TOKEN handling) | ⏳ Not Started |
| 2.3 | utils.py | Utility functions (logging, file operations) | ⏳ Not Started |
| 2.4 | project_manager.py | Update App.tsx, app.json with user values | ⏳ Not Started |
| 2.5 | build_manager.py | Run EAS builds using portable Node/EAS CLI | ⏳ Not Started |
| 2.6 | gui.py | Tkinter GUI (same look as current eas_build.py) | ⏳ Not Started |
| 2.7 | main.py | Entry point, EXPO_TOKEN first-run prompt | ⏳ Not Started |
| 2.8 | APK downloader | Auto-detect APK URL from logs, download to builds/ | ⏳ Not Started |
| 2.9 | Test Phase 2 | Test GUI launches and all features work | ⏳ Not Started |

---

## Phase 3: Project Template

**Status:** ⏳ Not Started  
**Description:** Configure the React Native project template to work with portable runtimes.

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 3.1 | Create project folder | Copy current project files to `project/` template folder | ⏳ Not Started |
| 3.2 | Update package.json | Ensure compatible with portable Node | ⏳ Not Started |
| 3.3 | Update eas.json | Configure for production builds | ⏳ Not Started |
| 3.4 | Default assets | Add default icon if user doesn't provide one | ⏳ Not Started |
| 3.5 | Test template | Verify build works with portable runtime | ⏳ Not Started |

---

## Phase 4: Launcher Scripts

**Status:** ⏳ Not Started  
**Description:** Create batch scripts for one-click launching of the builder.

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 4.1 | START-BUILDER.bat | Main launcher - sets PATH, launches GUI | ⏳ Not Started |
| 4.2 | START-BUILDER.ps1 | PowerShell alternative launcher | ⏳ Not Started |
| 4.3 | Handle edge cases | Spaces in path, missing files, error messages | ⏳ Not Started |
| 4.4 | Test on clean system | Test launcher on PC without Python/Node installed | ⏳ Not Started |

---

## Phase 5: Packaging

**Status:** ⏳ Not Started  
**Description:** Create the final distributable ZIP package.

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 5.1 | create_package.ps1 | Script to create distributable ZIP | ⏳ Not Started |
| 5.2 | Exclude unnecessary files | Remove setup/, .git/, dev files from package | ⏳ Not Started |
| 5.3 | Test package | Extract ZIP on clean PC, verify it works | ⏳ Not Started |
| 5.4 | Optimize size | Remove unused node_modules, compress assets | ⏳ Not Started |

---

## Phase 6: Documentation

**Status:** ⏳ Not Started  
**Description:** Create user-facing documentation.

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 6.1 | README.txt | Quick start instructions for end users | ⏳ Not Started |
| 6.2 | TROUBLESHOOTING.md | Common issues and solutions | ⏳ Not Started |
| 6.3 | Developer README | Instructions for updating/building package | ⏳ Not Started |

---

## Configuration Decisions

| Setting | Decision | Notes |
|---------|----------|-------|
| EXPO_TOKEN handling | Ask user on first run | Stored in config file after entry |
| Python runtime | WinPython portable | Includes tkinter, ~100 MB |
| Node runtime | Official Node.js portable | v20.11.0 LTS, ~70 MB |
| Icon handling | Both options | Browse for custom OR use default |
| Build output | Auto-download to builds/ | Also shows link in logs |
| Target package size | ~150-200 MB ZIP | ~300 MB extracted |

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Completed |
| 🔄 | In Progress |
| ⏳ | Not Started |
| ❌ | Blocked/Issue |

---

## Notes

- All portable runtimes will be stored in `runtime/` folder
- Setup scripts are for developer use only (not included in final package)
- Final package will only include: runtime/, builder/, project/, builds/, logs/, START-BUILDER.bat, README.txt

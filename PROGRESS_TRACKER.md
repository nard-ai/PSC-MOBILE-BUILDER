# PSC Mobile Builder - Portable Installation Progress Tracker

## Project Overview
**Branch:** `Portable-Installation`  
**Goal:** Create a completely self-contained Mobile App Builder that requires zero installation on POS systems  
**Last Updated:** February 7, 2025

---

## Phase Summary

| Phase No. | Features | Description | Progress |
|-----------|----------|-------------|----------|
| Phase 1 | Setup Infrastructure | Download scripts for Python & Node.js portable runtimes | ✅ Complete |
| Phase 2 | Builder Application | Flask Web UI with portable runtimes | 🔄 In Progress |
| Phase 3 | Project Template | Configure React Native template for portable builds | ⏳ Not Started |
| Phase 4 | Launcher Scripts | Create START-BUILDER.bat and environment setup | ⏳ Not Started |
| Phase 5 | Packaging | Create final distributable ZIP package | ⏳ Not Started |
| Phase 6 | Documentation | README, troubleshooting guide, user instructions | ⏳ Not Started |

---

## Phase 1: Setup Infrastructure

**Status:** ✅ Complete  
**Description:** Create PowerShell scripts to download and configure portable Python and Node.js runtimes with all required dependencies.

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 1.1 | Create setup folder structure | Create `setup/` folder for all setup scripts | ✅ Completed |
| 1.2 | download_python.ps1 | Script to download Python 3.11.8 Embedded (~15 MB) | ✅ Completed |
| 1.3 | download_node.ps1 | Script to download Node.js portable (~70 MB) | ✅ Completed |
| 1.4 | install_pip_packages.ps1 | Install flask, requests, pillow to portable Python | ✅ Completed |
| 1.5 | install_npm_packages.ps1 | Install eas-cli, @expo/cli to portable Node | ✅ Completed |
| 1.6 | verify_setup.ps1 | Verify all components installed correctly | ✅ Completed |
| 1.7 | Test Phase 1 | Run all scripts, verify runtime/ folder created | ✅ Completed |

**Phase 1 Results:**
- Python 3.11.8 Embedded installed at `runtime/python/`
- Node.js v20.11.0 installed at `runtime/node/`
- Flask, requests, pillow packages installed
- EAS CLI v16.32.0 and Expo CLI installed
- All 11 verification checks passed

---

## Phase 2: Builder Application

**Status:** 🔄 In Progress  
**Description:** Create Flask Web UI application that uses portable runtimes. (Changed from Tkinter since Python Embedded lacks tkinter module)

| Step No. | Task | Description | Status |
|----------|------|-------------|--------|
| 2.1 | Create builder folder structure | Create `builder/` folder with Flask app structure | ⏳ Not Started |
| 2.2 | app.py | Main Flask application with routes | ⏳ Not Started |
| 2.3 | config.py | Configuration module (paths, settings, EXPO_TOKEN handling) | ⏳ Not Started |
| 2.4 | templates/index.html | Main UI - form for app name, URL, icon, package ID | ⏳ Not Started |
| 2.5 | static/style.css | Styling for web UI | ⏳ Not Started |
| 2.6 | project_manager.py | Update App.tsx, app.json with user values | ⏳ Not Started |
| 2.7 | build_manager.py | Run EAS builds using portable Node/EAS CLI | ⏳ Not Started |
| 2.8 | APK downloader | Auto-detect APK URL from logs, download to builds/ | ⏳ Not Started |
| 2.9 | EXPO_TOKEN handling | First-run prompt, store in config file | ⏳ Not Started |
| 2.10 | Test Phase 2 | Test web UI at http://localhost:5000 | ⏳ Not Started |

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
| Python runtime | Python 3.11.8 Embedded | Lightweight ~15 MB, uses Flask for web UI |
| Node runtime | Official Node.js portable | v20.11.0 LTS, ~70 MB |
| UI approach | Flask Web UI | Opens browser to http://localhost:5000 |
| Icon handling | Both options | Browse for custom OR use default |
| Build output | Auto-download to builds/ | Also shows link in logs |
| Target package size | ~100-150 MB ZIP | ~200 MB extracted |

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

# Docker-based WebApp Wrapper Setup Guide

This guide will help you set up and use the WebApp Wrapper project using Docker, eliminating the need to install prerequisites locally.

## 🐳 What Docker Provides

With Docker, you get all these tools pre-installed in a container:
- ✅ Python 3.11
- ✅ Node.js LTS (v20)
- ✅ Expo CLI (latest)
- ✅ EAS CLI (latest)
- ✅ Git
- ✅ All required dependencies

## 🚀 Prerequisites

**Only Docker is required on your system:**
1. Install Docker Desktop: https://www.docker.com/products/docker-desktop
2. Start Docker Desktop
3. That's it! 🎉

## 📁 Project Structure

After setup, you'll have these Docker-related files:
```
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Container orchestration
├── docker-build.bat        # Windows script
├── docker-build.sh         # Linux/Mac script
├── .dockerignore           # Files to exclude from Docker
└── eas_build_docker.py     # Docker-aware Python GUI
```

## 🖥️ Getting Started (Windows)

### Method 1: Using the GUI Script
1. Open Command Prompt or PowerShell in your project folder
2. Run: `docker-build.bat`
3. Choose option **1** to build the Docker image
4. Choose option **2** to start services
5. Choose option **4** to run the Python GUI tool
6. Use the GUI to configure and build your app

### Method 2: Manual Commands
```cmd
# Build the Docker image (first time only)
docker-compose build webapp-wrapper

# Start the container
docker-compose up -d webapp-wrapper

# Run the Python GUI tool
docker-compose exec webapp-wrapper python3 eas_build_docker.py

# Or run EAS build directly
docker-compose exec webapp-wrapper eas build --platform android
```

## 🐧 Getting Started (Linux/Mac)

### Method 1: Using the GUI Script
1. Open terminal in your project folder
2. Make script executable: `chmod +x docker-build.sh`
3. Run: `./docker-build.sh`
4. Choose option **1** to build the Docker image
5. Choose option **2** to start services  
6. Choose option **4** to run the Python GUI tool
7. Use the GUI to configure and build your app

### Method 2: Manual Commands
```bash
# Build the Docker image (first time only)
docker-compose build webapp-wrapper

# Start the container
docker-compose up -d webapp-wrapper

# Run the Python GUI tool
docker-compose exec webapp-wrapper python3 eas_build_docker.py

# Or run EAS build directly
docker-compose exec webapp-wrapper eas build --platform android
```

## 🛠️ Using the Docker Menu System

The `docker-build` scripts provide an interactive menu:

```
=== WebApp Wrapper Docker Tools ===
1. Build Docker image          # First time setup
2. Start services             # Start the container
3. Install dependencies       # Install npm packages
4. Run Python GUI tool        # Your main interface
5. Run EAS build             # Direct build command
6. Open container shell      # For debugging
7. View logs                 # Check container logs
8. Stop services             # Stop the container
9. Cleanup                   # Remove containers
0. Exit
```

## 🎯 Typical Workflow

### First Time Setup:
1. Run `docker-build.bat` (Windows) or `./docker-build.sh` (Linux/Mac)
2. Choose option **1** (Build Docker image) - this takes a few minutes
3. Choose option **2** (Start services)
4. Choose option **3** (Install dependencies)

### Regular Development:
1. Choose option **4** (Run Python GUI tool)
2. Configure your app URL and name
3. Click "Save Config"
4. Click "Start Build"
5. Wait for the build to complete

### EAS Login (First Time):
When you first run a build, you'll need to login to Expo:
```bash
# This happens automatically, but you can also run manually:
docker-compose exec webapp-wrapper eas login
```

## 📱 Building Your App

### Using the GUI (Recommended):
1. **App URL**: Enter your web application URL (e.g., `http://192.168.1.109/NEWKIOSK`)
2. **App Name**: Enter your app's display name (e.g., `My Kiosk App`)
3. Click **Save Config** to update App.tsx and app.json
4. Click **Start Build** to create your APK

### Direct Command:
```bash
docker-compose exec webapp-wrapper eas build --platform android --non-interactive
```

## 🗂️ File Access

Your project files are automatically synchronized between your computer and the Docker container:
- Edit files normally on your computer
- Changes are immediately available in the container
- Build outputs appear in your local `build/` folder
- Logs are saved to your local `logs/` folder

## 🔧 Troubleshooting

### Container Won't Start:
```bash
# Check if Docker is running
docker info

# View container logs
docker-compose logs webapp-wrapper

# Restart services
docker-compose restart webapp-wrapper
```

### Permission Issues (Linux/Mac):
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
```

### Build Failures:
1. Check the logs in the GUI
2. Ensure you're logged into EAS: `docker-compose exec webapp-wrapper eas whoami`
3. Try the "Fix Gradle" button in the GUI
4. Check your app.json configuration

### Out of Disk Space:
```bash
# Clean up Docker resources
docker system prune -a
docker volume prune
```

## 📊 Port Mapping

The Docker setup exposes these ports:
- **3000**: Expo development server
- **8081**: Metro bundler
- **19000-19002**: Expo development tools
- **8080**: Optional web server for testing

## 🔄 Updating Dependencies

To update Expo CLI, EAS CLI, or other tools:
```bash
# Rebuild the Docker image
docker-compose build --no-cache webapp-wrapper

# Or update specific tools in running container
docker-compose exec webapp-wrapper npm install -g @expo/cli@latest eas-cli@latest
```

## 🧹 Cleanup

### Stop and Remove Containers:
```bash
docker-compose down

# Remove all data (be careful!)
docker-compose down -v
```

### Remove Docker Image:
```bash
docker rmi webapp-wrapper-dev:latest
```

## 🆘 Getting Help

### Check Container Status:
```bash
docker-compose ps
```

### Access Container Shell:
```bash
docker-compose exec webapp-wrapper bash
```

### View All Logs:
```bash
docker-compose logs -f
```

### Verify Tools Installation:
```bash
docker-compose exec webapp-wrapper python3 --version
docker-compose exec webapp-wrapper node --version
docker-compose exec webapp-wrapper eas --version
docker-compose exec webapp-wrapper expo --version
```

## 🎓 Tips for Beginners

1. **Start Simple**: Use the GUI (option 4) instead of manual commands
2. **One Step at a Time**: Follow the workflow order - build image first, then start services
3. **Check Docker Desktop**: Make sure it's running before starting
4. **Save Your Work**: Always click "Save Config" before building
5. **Be Patient**: The first Docker build takes 5-10 minutes
6. **Read the Logs**: The GUI shows detailed progress and error messages

## 🔗 Useful Commands Reference

```bash
# Quick start (after first setup)
docker-compose up -d && docker-compose exec webapp-wrapper python3 eas_build_docker.py

# Check what's running
docker ps

# Stop everything
docker-compose stop

# Start fresh
docker-compose down && docker-compose up -d

# Update and rebuild
git pull && docker-compose build --no-cache
```

Remember: With Docker, you never need to install Python, Node.js, or any other tools locally! Everything runs in the container. 🚀
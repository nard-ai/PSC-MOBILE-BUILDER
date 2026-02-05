#!/bin/bash
# Docker Build Script for WebApp Wrapper
# This script runs the EAS build process inside a Docker container

set -e  # Exit on any error

echo "🚀 Starting WebApp Wrapper Docker Build..."

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker Desktop first."
        exit 1
    fi
    echo "✅ Docker is running"
}

# Function to build Docker image
build_image() {
    echo "🏗️  Building Docker image..."
    docker-compose build webapp-wrapper
    echo "✅ Docker image built successfully"
}

# Function to start services
start_services() {
    echo "🚀 Starting Docker services..."
    docker-compose up -d webapp-wrapper
    echo "✅ Services started"
}

# Function to run EAS build
run_eas_build() {
    echo "📱 Running EAS build inside container..."
    
    # Check if EAS is logged in
    docker-compose exec webapp-wrapper eas whoami || {
        echo "🔐 Please login to EAS first:"
        docker-compose exec webapp-wrapper eas login
    }
    
    # Run the build
    docker-compose exec webapp-wrapper eas build --platform android --non-interactive
    
    echo "✅ EAS build completed"
}

# Function to run Python GUI tool
run_python_gui() {
    echo "🖥️  Starting Python GUI tool..."
    docker-compose exec webapp-wrapper python3 eas_build.py
}

# Function to install dependencies
install_dependencies() {
    echo "📦 Installing Node.js dependencies..."
    docker-compose exec webapp-wrapper npm install
    echo "✅ Dependencies installed"
}

# Function to clean up
cleanup() {
    echo "🧹 Cleaning up..."
    docker-compose down
    echo "✅ Cleanup completed"
}

# Main menu
show_menu() {
    echo ""
    echo "=== WebApp Wrapper Docker Tools ==="
    echo "1. Build Docker image"
    echo "2. Start services"
    echo "3. Install dependencies"
    echo "4. Run Python GUI tool"
    echo "5. Run EAS build"
    echo "6. Open container shell"
    echo "7. View logs"
    echo "8. Stop services"
    echo "9. Cleanup"
    echo "0. Exit"
    echo ""
}

# Handle command line arguments
case "$1" in
    "build")
        check_docker
        build_image
        ;;
    "start")
        check_docker
        start_services
        ;;
    "install")
        check_docker
        install_dependencies
        ;;
    "gui")
        check_docker
        run_python_gui
        ;;
    "eas-build")
        check_docker
        run_eas_build
        ;;
    "shell")
        check_docker
        echo "🐚 Opening container shell..."
        docker-compose exec webapp-wrapper bash
        ;;
    "logs")
        check_docker
        docker-compose logs -f webapp-wrapper
        ;;
    "stop")
        check_docker
        echo "⏹️  Stopping services..."
        docker-compose stop
        ;;
    "cleanup")
        check_docker
        cleanup
        ;;
    *)
        check_docker
        while true; do
            show_menu
            read -p "Choose an option (0-9): " choice
            case $choice in
                1) build_image ;;
                2) start_services ;;
                3) install_dependencies ;;
                4) run_python_gui ;;
                5) run_eas_build ;;
                6) 
                    echo "🐚 Opening container shell..."
                    docker-compose exec webapp-wrapper bash
                    ;;
                7) docker-compose logs -f webapp-wrapper ;;
                8) 
                    echo "⏹️  Stopping services..."
                    docker-compose stop
                    ;;
                9) cleanup ;;
                0) 
                    echo "👋 Goodbye!"
                    exit 0
                    ;;
                *) echo "❌ Invalid option. Please choose 0-9." ;;
            esac
        done
        ;;
esac
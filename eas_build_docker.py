import os
import json
import shutil
import subprocess
import threading
import tkinter as tk
from tkinter import messagebox, scrolledtext, filedialog, ttk
import platform

# Detect if running in Docker container
RUNNING_IN_DOCKER = os.path.exists('/.dockerenv')
IS_WINDOWS = platform.system() == "Windows"

if RUNNING_IN_DOCKER:
    # Running inside Docker container
    EAS_CLI = shutil.which("eas") or "/usr/local/bin/eas"
    PROJECT_DIR = "/app"
    print("🐳 Running inside Docker container")
else:
    # Running on host system
    EAS_CLI = shutil.which("eas")
    if not EAS_CLI:
        messagebox.showerror(
            "EAS CLI Missing",
            "EAS CLI not found.\nFor local development:\n1. Install Node.js\n2. Run: npm install -g eas-cli\n\nOr use Docker setup with docker-build.bat"
        )
        exit(1)
    
    # Ask for project directory if not in Docker
    root = tk.Tk()
    root.withdraw()
    selected_dir = filedialog.askdirectory(title="Select Web App Project Directory")
    if selected_dir:
        PROJECT_DIR = selected_dir
    else:
        PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
    root.destroy()

print(f"Using project directory: {PROJECT_DIR}")

FALLBACK_EXPO_TOKEN = "IxQ90f96kL7P5gYL8TnSHD41tyY2W1T1eoR1v065"

APP_TSX_PATH = os.path.join(PROJECT_DIR, "App.tsx")
APP_JSON_PATH = os.path.join(PROJECT_DIR, "app.json")


def run_command(cmd, cwd=None, shell=True):
    """Run command with proper environment setup"""
    if cwd is None:
        cwd = PROJECT_DIR
    
    # Set up environment
    env = os.environ.copy()
    if RUNNING_IN_DOCKER:
        # Ensure proper PATH in Docker
        env['PATH'] = f"/usr/local/bin:/usr/bin:/bin:{env.get('PATH', '')}"
    
    try:
        if isinstance(cmd, str):
            result = subprocess.run(
                cmd, 
                shell=shell, 
                cwd=cwd, 
                capture_output=True, 
                text=True, 
                env=env,
                timeout=300  # 5 minute timeout
            )
        else:
            result = subprocess.run(
                cmd, 
                cwd=cwd, 
                capture_output=True, 
                text=True, 
                env=env,
                timeout=300
            )
        return result
    except subprocess.TimeoutExpired:
        log("⏰ Command timed out after 5 minutes\n")
        return None
    except Exception as e:
        log(f"❌ Error running command: {e}\n")
        return None


def docker_exec_command(cmd):
    """Execute command inside Docker container from host"""
    if RUNNING_IN_DOCKER:
        # Already in container, run directly
        return run_command(cmd)
    
    # From host, execute in container
    docker_cmd = f"docker-compose exec webapp-wrapper {cmd}"
    return run_command(docker_cmd, shell=True)


def check_docker_setup():
    """Check if Docker setup is available and suggest using it"""
    if RUNNING_IN_DOCKER:
        return True
    
    # Check if Docker Compose file exists
    docker_compose_path = os.path.join(PROJECT_DIR, "docker-compose.yml")
    if os.path.exists(docker_compose_path):
        response = messagebox.askyesno(
            "Docker Setup Available", 
            "Docker setup is available for this project.\n\n"
            "Using Docker is recommended as it includes all prerequisites.\n\n"
            "Would you like to switch to Docker mode?\n\n"
            "Click 'Yes' to use Docker or 'No' to continue locally."
        )
        if response:
            messagebox.showinfo(
                "Switch to Docker", 
                "Please close this application and use:\n\n"
                "Windows: docker-build.bat\n"
                "Linux/Mac: ./docker-build.sh\n\n"
                "Then choose option 4 to run the GUI tool."
            )
            exit(0)
    return False


def read_app_url():
    """Extract APP_URL from App.tsx"""
    try:
        with open(APP_TSX_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
            for line in content.split('\n'):
                if 'APP_URL' in line and '=' in line:
                    url = line.split('=')[1].strip().strip("';\"")
                    return url
    except Exception as e:
        log(f"Error reading App.tsx: {e}\n")
    return ""


def read_app_config():
    """Read app.json configuration"""
    try:
        with open(APP_JSON_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        log(f"Error reading app.json: {e}\n")
    return {}


def validate_icon_paths():
    """Validate that all icon paths in app.json exist"""
    config = read_app_config()
    expo = config.get('expo', {})
    errors = []
    
    # Check main icon
    icon_path = expo.get('icon', '')
    if icon_path:
        full_path = os.path.join(PROJECT_DIR, icon_path.lstrip('./'))
        if not os.path.exists(full_path):
            errors.append(f"Main icon not found: {icon_path} (looking at {full_path})")
    
    # Check splash image
    splash_image = expo.get('splash', {}).get('image', '')
    if splash_image:
        full_path = os.path.join(PROJECT_DIR, splash_image.lstrip('./'))
        if not os.path.exists(full_path):
            errors.append(f"Splash image not found: {splash_image} (looking at {full_path})")
    
    # Check adaptive icon
    adaptive_icon = expo.get('android', {}).get('adaptiveIcon', {}).get('foregroundImage', '')
    if adaptive_icon:
        full_path = os.path.join(PROJECT_DIR, adaptive_icon.lstrip('./'))
        if not os.path.exists(full_path):
            errors.append(f"Adaptive icon not found: {adaptive_icon} (looking at {full_path})")
    
    return errors


def update_app_url(new_url):
    """Update APP_URL in App.tsx"""
    try:
        with open(APP_TSX_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
        
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'APP_URL' in line and '=' in line:
                lines[i] = f"const APP_URL = '{new_url}';"
                break
        
        with open(APP_TSX_PATH, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        
        return True
    except Exception as e:
        log(f"Error updating App.tsx: {e}\n")
        return False


def update_app_config(app_name):
    """Update app.json with new name"""
    try:
        config = read_app_config()
        
        if app_name:
            config['expo']['name'] = app_name
            if 'android' in config['expo']:
                config['expo']['android']['label'] = app_name
        
        with open(APP_JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
        
        return True
    except Exception as e:
        log(f"Error updating app.json: {e}\n")
        return False


def check_eas_login():
    """Check if user is logged into EAS"""
    try:
        result = run_command("eas whoami")
        if result and result.returncode == 0:
            return True, result.stdout.strip()
        return False, "Not logged in"
    except Exception as e:
        return False, str(e)


def eas_login():
    """Handle EAS login"""
    if RUNNING_IN_DOCKER:
        log("🔐 Please login to EAS CLI...\n")
        result = run_command("eas login")
        if result and result.returncode == 0:
            log("✅ Successfully logged in to EAS\n")
            return True
        else:
            log("❌ Failed to login to EAS\n")
            return False
    else:
        messagebox.showinfo("EAS Login", "Please run 'eas login' in your terminal first.")
        return False


def save_config():
    """Save all configuration changes"""
    new_url = url_entry.get().strip()
    new_name = name_entry.get().strip()
    
    if not new_url:
        messagebox.showwarning("Validation", "App URL cannot be empty!")
        return
    
    if not new_name:
        messagebox.showwarning("Validation", "App Name cannot be empty!")
        return
    
    log("Saving configuration...\n")
    
    success = True
    
    if new_url != read_app_url():
        if update_app_url(new_url):
            log(f"✅ Updated APP_URL to: {new_url}\n")
        else:
            success = False
    
    current_config = read_app_config()
    current_name = current_config.get('expo', {}).get('name', '')
    
    if new_name != current_name:
        if update_app_config(new_name):
            log(f"✅ Updated app name to: {new_name}\n")
        else:
            success = False
    
    if success:
        log("✅ Configuration saved successfully!\n")
        messagebox.showinfo("Success", "Configuration saved successfully!")
    else:
        log("❌ Some configuration updates failed!\n")
        messagebox.showerror("Error", "Some configuration updates failed!")


def run_build():
    """Run EAS build"""
    # Validate configuration first
    icon_errors = validate_icon_paths()
    if icon_errors:
        error_msg = "Icon validation failed:\n\n" + "\n".join(icon_errors)
        log("❌ " + error_msg + "\n")
        messagebox.showerror("Icon Validation Failed", error_msg)
        return
    
    # Check EAS login
    is_logged_in, login_info = check_eas_login()
    if not is_logged_in:
        log("❌ Not logged into EAS CLI\n")
        if not eas_login():
            return
    else:
        log(f"✅ Logged into EAS as: {login_info}\n")
    
    build_button.config(state='disabled', text='Building...')
    log_text.delete(1.0, tk.END)
    log("🚀 Starting EAS build...\n")
    
    def build_thread():
        try:
            # Install dependencies first
            log("📦 Installing dependencies...\n")
            result = run_command("npm install")
            if result and result.returncode != 0:
                log(f"❌ npm install failed: {result.stderr}\n")
                messagebox.showerror("Build Failed", "Failed to install dependencies")
                return
            
            # Run EAS build
            log("🏗️ Running EAS build for Android...\n")
            result = run_command("eas build --platform android --non-interactive")
            
            if result and result.returncode == 0:
                log("✅ Build completed successfully!\n")
                log(f"Output: {result.stdout}\n")
                messagebox.showinfo("Success", "Build completed successfully!")
            else:
                error_msg = result.stderr if result else "Unknown error occurred"
                log(f"❌ Build failed: {error_msg}\n")
                messagebox.showerror("Build Failed", f"Build failed:\n{error_msg}")
        
        except Exception as e:
            log(f"❌ Build error: {e}\n")
            messagebox.showerror("Build Error", f"Build error: {e}")
        
        finally:
            build_button.config(state='normal', text='Start Build')
    
    threading.Thread(target=build_thread, daemon=True).start()


def fix_gradle():
    """Fix common Gradle issues"""
    log("🔧 Attempting to fix Gradle issues...\n")
    
    def fix_thread():
        try:
            # Clean build
            log("Cleaning Gradle build...\n")
            result = run_command("cd android && ./gradlew clean")
            if result:
                log(result.stdout + "\n")
            
            # Update dependencies
            log("Updating Gradle wrapper...\n")
            result = run_command("cd android && ./gradlew wrapper --gradle-version=8.0")
            if result:
                log(result.stdout + "\n")
            
            log("✅ Gradle fix completed!\n")
            messagebox.showinfo("Success", "Gradle fix completed!")
        
        except Exception as e:
            log(f"❌ Gradle fix error: {e}\n")
            messagebox.showerror("Error", f"Gradle fix error: {e}")
    
    threading.Thread(target=fix_thread, daemon=True).start()


def log(message):
    """Add message to log text widget"""
    log_text.insert(tk.END, message)
    log_text.see(tk.END)
    root.update_idletasks()


def create_gui():
    """Create the main GUI"""
    global root, url_entry, name_entry, build_button, log_text
    
    root = tk.Tk()
    root.title(f"WebApp Wrapper Builder {'(Docker)' if RUNNING_IN_DOCKER else '(Local)'}")
    root.geometry("800x700")
    
    # Main frame
    main_frame = ttk.Frame(root, padding="10")
    main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
    
    # Configure grid weights
    root.columnconfigure(0, weight=1)
    root.rowconfigure(0, weight=1)
    main_frame.columnconfigure(1, weight=1)
    
    row = 0
    
    # Environment info
    env_label = ttk.Label(main_frame, text=f"Environment: {'Docker Container' if RUNNING_IN_DOCKER else 'Local System'}")
    env_label.grid(row=row, column=0, columnspan=2, pady=(0, 10), sticky='w')
    row += 1
    
    # Project directory
    ttk.Label(main_frame, text="Project Directory:").grid(row=row, column=0, sticky='w', pady=5)
    ttk.Label(main_frame, text=PROJECT_DIR).grid(row=row, column=1, sticky='w', pady=5)
    row += 1
    
    # App URL
    ttk.Label(main_frame, text="App URL:").grid(row=row, column=0, sticky='w', pady=5)
    url_entry = ttk.Entry(main_frame, width=50)
    url_entry.grid(row=row, column=1, sticky='ew', pady=5)
    url_entry.insert(0, read_app_url())
    row += 1
    
    # App Name
    ttk.Label(main_frame, text="App Name:").grid(row=row, column=0, sticky='w', pady=5)
    name_entry = ttk.Entry(main_frame, width=50)
    name_entry.grid(row=row, column=1, sticky='ew', pady=5)
    current_config = read_app_config()
    name_entry.insert(0, current_config.get('expo', {}).get('name', ''))
    row += 1
    
    # Buttons frame
    buttons_frame = ttk.Frame(main_frame)
    buttons_frame.grid(row=row, column=0, columnspan=2, pady=10, sticky='ew')
    
    ttk.Button(buttons_frame, text="Save Config", command=save_config).pack(side='left', padx=5)
    build_button = ttk.Button(buttons_frame, text="Start Build", command=run_build)
    build_button.pack(side='left', padx=5)
    ttk.Button(buttons_frame, text="Fix Gradle", command=fix_gradle).pack(side='left', padx=5)
    
    if not RUNNING_IN_DOCKER:
        ttk.Button(buttons_frame, text="Setup Docker", command=lambda: setup_docker_info()).pack(side='left', padx=5)
    
    row += 1
    
    # Log area
    ttk.Label(main_frame, text="Build Log:").grid(row=row, column=0, sticky='w', pady=(10, 5))
    row += 1
    
    log_text = scrolledtext.ScrolledText(main_frame, height=20, width=80)
    log_text.grid(row=row, column=0, columnspan=2, sticky='nsew', pady=5)
    
    main_frame.rowconfigure(row, weight=1)
    
    # Initial log message
    if RUNNING_IN_DOCKER:
        log("🐳 Running in Docker container - all prerequisites available\n")
    else:
        log("💻 Running on local system\n")
        log("ℹ️  Consider using Docker for better dependency management\n")
    
    # Validate icons on startup
    icon_errors = validate_icon_paths()
    if icon_errors:
        log("⚠️  Icon validation warnings:\n")
        for error in icon_errors:
            log(f"   - {error}\n")
        log("\n")
    
    return root


def setup_docker_info():
    """Show information about setting up Docker"""
    info = """Docker Setup Instructions:

1. Install Docker Desktop from: https://www.docker.com/products/docker-desktop

2. Make sure Docker Desktop is running

3. Use the provided Docker scripts:
   - Windows: Run docker-build.bat
   - Linux/Mac: Run ./docker-build.sh

4. The Docker setup includes:
   - Python 3.11
   - Node.js LTS
   - Expo CLI
   - EAS CLI  
   - Git
   - All required dependencies

5. Choose option 4 in the Docker menu to run this GUI tool

This eliminates the need to install prerequisites locally!"""
    
    messagebox.showinfo("Docker Setup", info)


if __name__ == "__main__":
    # Check Docker setup availability if not running in Docker
    check_docker_setup()
    
    try:
        root = create_gui()
        root.mainloop()
    except Exception as e:
        print(f"Error starting GUI: {e}")
        if not RUNNING_IN_DOCKER:
            messagebox.showerror("Error", f"Error starting GUI: {e}")
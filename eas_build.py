import os
import json
import shutil
import subprocess
import threading
import tkinter as tk
from tkinter import messagebox, scrolledtext, filedialog, ttk

EAS_CLI = shutil.which("eas")
if not EAS_CLI:
    messagebox.showerror(
        "EAS CLI Missing",
        "EAS CLI not found.\nInstall it using:\nnpm install -g eas-cli"
    )
    exit(1)

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))

root = tk.Tk()
root.withdraw()
selected_dir = filedialog.askdirectory(title="Select Web App Project Directory")
if selected_dir:
    PROJECT_DIR = selected_dir
root.destroy()

print(f"Using project directory: {PROJECT_DIR}")

FALLBACK_EXPO_TOKEN = "IxQ90f96kL7P5gYL8TnSHD41tyY2W1T1eoR1v065"

APP_TSX_PATH = os.path.join(PROJECT_DIR, "App.tsx")
APP_JSON_PATH = os.path.join(PROJECT_DIR, "app.json")


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
    
    if new_name:
        if update_app_config(new_name):
            log(f"✅ Updated app configuration\n")
            log(f"   - App Name: {new_name}\n")
        else:
            success = False
    
    if success:
        messagebox.showinfo("Success", "Configuration saved successfully!")
    else:
        messagebox.showerror("Error", "Failed to save some configuration. Check logs.")


def run_build():
    # Validate icon paths before building
    log_area.delete(1.0, tk.END)
    log("Validating configuration...\n")
    
    icon_errors = validate_icon_paths()
    if icon_errors:
        log("❌ Icon path errors found:\n")
        for error in icon_errors:
            log(f"   - {error}\n")
        log("\nPlease fix these issues in your app.json file before building.\n")
        messagebox.showerror(
            "Configuration Error",
            "Icon files not found. Check the logs for details.\n\n" +
            "Please ensure all icon paths in app.json point to existing files."
        )
        return
    
    log("✅ Configuration validated successfully\n\n")
    
    token = os.environ.get("EXPO_TOKEN")
    if not token:
        token = FALLBACK_EXPO_TOKEN
        messagebox.showwarning(
            "Using Default Token",
            "EXPO_TOKEN is not set. Using default token for this build."
        )
    os.environ["EXPO_TOKEN"] = token

    build_button.config(state=tk.DISABLED)
    save_button.config(state=tk.DISABLED)
    log("Starting EAS build...\n")

    os.chdir(PROJECT_DIR)

    command = [
        EAS_CLI,
        "build",
        "--platform", "android",
        "--profile", "production",
        "--non-interactive"
    ]

    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        for line in process.stdout:
            log(line)

        process.wait()

        if process.returncode == 0:
            log("\n✅ Build completed successfully!\n")
            messagebox.showinfo("Success", "Build completed successfully!")
        else:
            log(f"\n❌ Build failed (code {process.returncode})\n")
            messagebox.showerror("Build Failed", "Check logs for details.")

    except Exception as e:
        messagebox.showerror("Error", str(e))

    build_button.config(state=tk.NORMAL)
    save_button.config(state=tk.NORMAL)


def start_build():
    threading.Thread(target=run_build, daemon=True).start()


def retry_build():
    """Retry the build (useful for network timeouts)"""
    response = messagebox.askyesno(
        "Retry Build",
        "This will retry the build. Network timeouts often resolve on retry.\n\nContinue?"
    )
    if response:
        start_build()


def fix_gradle_config():
    """Fix Gradle configuration to avoid JFrog timeout issues"""
    try:
        android_dir = os.path.join(PROJECT_DIR, "android")
        
     
        if not os.path.exists(android_dir):
            messagebox.showinfo(
                "Info",
                "Android directory not found. This fix should be applied after the first build attempt creates the android folder."
            )
            return
        
        build_gradle_path = os.path.join(android_dir, "build.gradle")
        
      
        if os.path.exists(build_gradle_path):
            backup_path = build_gradle_path + ".backup"
            shutil.copy2(build_gradle_path, backup_path)
            log(f"✅ Backed up build.gradle to {backup_path}\n")
        
     
        gradle_content = """// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    ext {
        buildToolsVersion = "33.0.0"
        minSdkVersion = 21
        compileSdkVersion = 33
        targetSdkVersion = 33
        
        ndkVersion = "23.1.7779620"
    }
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    dependencies {
        classpath("com.android.tools.build:gradle")
        classpath("com.facebook.react:react-native-gradle-plugin")
    }
}

allprojects {
    repositories {
        maven {
            // All of React Native (JS, Obj-C sources, Android binaries) is installed from npm
            url("$rootDir/../node_modules/react-native/android")
        }
        maven {
            // Android JSC is installed from npm
            url("$rootDir/../node_modules/jsc-android/dist")
        }
        google()
        mavenCentral()
        maven { url 'https://www.jitpack.io' }
    }
}
"""
        
        with open(build_gradle_path, 'w', encoding='utf-8') as f:
            f.write(gradle_content)
        
        log("✅ Updated android/build.gradle with proper repository configuration\n")
        
        # Also create gradle.properties
        gradle_properties_path = os.path.join(android_dir, "gradle.properties")
        properties_content = """# Project-wide Gradle settings.

org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.configureondemand=true

android.useAndroidX=true
android.enableJetifier=true

# Increase timeout for slow connections
systemProp.org.gradle.internal.http.connectionTimeout=180000
systemProp.org.gradle.internal.http.socketTimeout=180000
"""
        
        with open(gradle_properties_path, 'w', encoding='utf-8') as f:
            f.write(properties_content)
        
        log("✅ Created/updated android/gradle.properties with timeout settings\n")
        
        messagebox.showinfo(
            "Success",
            "Gradle configuration has been fixed!\n\nNow retry the build."
        )
        
    except Exception as e:
        log(f"❌ Error fixing Gradle config: {e}\n")
        messagebox.showerror("Error", f"Failed to fix Gradle config: {e}")


def log(message):
    log_area.insert(tk.END, message)
    log_area.see(tk.END)


# Main UI
root = tk.Tk()
root.title("Mobile App Builder/Installer")
root.configure(bg="#0a57c9")
root.geometry("1000x700")
root.resizable(False, False)

# Title
title = tk.Label(
    root,
    text="Mobile App Builder/Installer",
    font=("Segoe UI", 16, "bold"),
    bg="#0a57c9",
    fg="white"
)
title.pack(pady=10)

# Configuration Frame
config_frame = tk.LabelFrame(
    root,
    text="App Configuration",
    font=("Segoe UI", 11, "bold"),
    bg="#f0f0f0",
    padx=15,
    pady=10
)
config_frame.pack(padx=10, pady=5, fill=tk.X)

# App URL
url_label = tk.Label(config_frame, text="App URL:", font=("Segoe UI", 10), bg="#f0f0f0")
url_label.grid(row=0, column=0, sticky=tk.W, pady=5)
url_entry = tk.Entry(config_frame, font=("Segoe UI", 10), width=60)
url_entry.grid(row=0, column=1, pady=5, padx=5, sticky=tk.EW)
url_entry.insert(0, read_app_url())

# App Name
name_label = tk.Label(config_frame, text="App Name:", font=("Segoe UI", 10), bg="#f0f0f0")
name_label.grid(row=1, column=0, sticky=tk.W, pady=5)
name_entry = tk.Entry(config_frame, font=("Segoe UI", 10), width=60)
name_entry.grid(row=1, column=1, pady=5, padx=5, sticky=tk.EW)
config = read_app_config()
name_entry.insert(0, config.get('expo', {}).get('name', ''))

config_frame.columnconfigure(1, weight=1)

# Buttons Frame
button_frame = tk.Frame(root, bg="#0a57c9")
button_frame.pack(pady=10)

save_button = tk.Button(
    button_frame,
    text="💾 Save Configuration",
    font=("Segoe UI", 11),
    width=20,
    height=2,
    command=save_config,
    bg="#28a745",
    fg="white"
)
save_button.grid(row=0, column=0, padx=5)

build_button = tk.Button(
    button_frame,
    text="🚀 Build Android App",
    font=("Segoe UI", 11),
    width=20,
    height=2,
    command=start_build,
    bg="#007bff",
    fg="white"
)
build_button.grid(row=0, column=1, padx=5)

retry_button = tk.Button(
    button_frame,
    text="🔄 Retry Build",
    font=("Segoe UI", 11),
    width=20,
    height=2,
    command=retry_build,
    bg="#ffc107",
    fg="black"
)
retry_button.grid(row=0, column=2, padx=5)

fix_button = tk.Button(
    button_frame,
    text="🔧 Fix Gradle Config",
    font=("Segoe UI", 11),
    width=20,
    height=2,
    command=fix_gradle_config,
    bg="#ff6b6b",
    fg="white"
)
fix_button.grid(row=1, column=0, columnspan=3, pady=5)

# Log Area
log_label = tk.Label(
    root,
    text="Build Logs:",
    font=("Segoe UI", 10, "bold"),
    bg="#0a57c9",
    fg="white"
)
log_label.pack(anchor=tk.W, padx=10)

log_area = scrolledtext.ScrolledText(
    root,
    width=105,
    height=15,
    font=("Consolas", 9),
    bg="#1e1e1e",
    fg="#d4d4d4"
)
log_area.pack(padx=10, pady=5)
root.mainloop()
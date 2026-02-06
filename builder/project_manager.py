"""
Project Manager for PSC Mobile Builder
Handles updates to App.tsx and app.json configuration
"""
import os
import json
import shutil
from . import config


def read_app_url():
    """Extract APP_URL from App.tsx"""
    try:
        with open(config.APP_TSX_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
            for line in content.split('\n'):
                if 'APP_URL' in line and '=' in line:
                    url = line.split('=')[1].strip().strip("';\"")
                    return url
    except Exception as e:
        print(f"Error reading App.tsx: {e}")
    return ""


def update_app_url(new_url):
    """Update APP_URL in App.tsx"""
    try:
        with open(config.APP_TSX_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
        
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'APP_URL' in line and '=' in line:
                lines[i] = f"const APP_URL = '{new_url}';"
                break
        
        with open(config.APP_TSX_PATH, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        
        return True, f"Updated APP_URL to: {new_url}"
    except Exception as e:
        return False, f"Error updating App.tsx: {e}"


def read_app_config():
    """Read app.json configuration"""
    try:
        with open(config.APP_JSON_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error reading app.json: {e}")
    return {}


def update_app_config(app_name=None, package_id=None):
    """Update app.json with new name and/or package ID"""
    try:
        app_config = read_app_config()
        
        if app_name:
            app_config['expo']['name'] = app_name
            if 'android' in app_config['expo']:
                app_config['expo']['android']['label'] = app_name
        
        if package_id:
            if 'android' not in app_config['expo']:
                app_config['expo']['android'] = {}
            app_config['expo']['android']['package'] = package_id
        
        with open(config.APP_JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(app_config, f, indent=2)
        
        return True, "Updated app.json successfully"
    except Exception as e:
        return False, f"Error updating app.json: {e}"


def validate_icon_paths():
    """Validate that all icon paths in app.json exist"""
    app_config = read_app_config()
    expo = app_config.get('expo', {})
    errors = []
    
    # Check main icon
    icon_path = expo.get('icon', '')
    if icon_path:
        full_path = os.path.join(config.PROJECT_DIR, icon_path.lstrip('./'))
        if not os.path.exists(full_path):
            errors.append(f"Main icon not found: {icon_path}")
    
    # Check splash image
    splash_image = expo.get('splash', {}).get('image', '')
    if splash_image:
        full_path = os.path.join(config.PROJECT_DIR, splash_image.lstrip('./'))
        if not os.path.exists(full_path):
            errors.append(f"Splash image not found: {splash_image}")
    
    # Check adaptive icon
    adaptive_icon = expo.get('android', {}).get('adaptiveIcon', {}).get('foregroundImage', '')
    if adaptive_icon:
        full_path = os.path.join(config.PROJECT_DIR, adaptive_icon.lstrip('./'))
        if not os.path.exists(full_path):
            errors.append(f"Adaptive icon not found: {adaptive_icon}")
    
    return errors


def update_icon(icon_path):
    """Copy new icon to assets and update app.json"""
    try:
        if not os.path.exists(icon_path):
            return False, f"Icon file not found: {icon_path}"
        
        # Create assets folder if it doesn't exist
        os.makedirs(config.ASSETS_DIR, exist_ok=True)
        
        # Copy icon to assets
        icon_filename = "icon.png"
        dest_path = os.path.join(config.ASSETS_DIR, icon_filename)
        shutil.copy2(icon_path, dest_path)
        
        # Update app.json to point to new icon
        app_config = read_app_config()
        app_config['expo']['icon'] = f"./assets/{icon_filename}"
        
        # Also update splash and adaptive icon
        if 'splash' in app_config['expo']:
            app_config['expo']['splash']['image'] = f"./assets/{icon_filename}"
        
        if 'android' in app_config['expo']:
            if 'adaptiveIcon' not in app_config['expo']['android']:
                app_config['expo']['android']['adaptiveIcon'] = {}
            app_config['expo']['android']['adaptiveIcon']['foregroundImage'] = f"./assets/{icon_filename}"
        
        with open(config.APP_JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(app_config, f, indent=2)
        
        return True, f"Updated icon to: {icon_filename}"
    except Exception as e:
        return False, f"Error updating icon: {e}"


def get_current_config():
    """Get current project configuration for display in UI"""
    app_config = read_app_config()
    expo = app_config.get('expo', {})
    
    return {
        'app_url': read_app_url(),
        'app_name': expo.get('name', ''),
        'package_id': expo.get('android', {}).get('package', ''),
        'icon': expo.get('icon', ''),
        'version': expo.get('version', '1.0.0'),
    }


def save_all_config(app_url, app_name, package_id=None):
    """Save all configuration changes at once"""
    results = []
    success = True
    
    # Update App URL
    if app_url:
        current_url = read_app_url()
        if app_url != current_url:
            ok, msg = update_app_url(app_url)
            results.append(msg)
            if not ok:
                success = False
    
    # Update app.json
    if app_name or package_id:
        ok, msg = update_app_config(app_name, package_id)
        results.append(msg)
        if not ok:
            success = False
    
    return success, results


def fix_gradle_config():
    """Fix Gradle configuration to avoid JFrog timeout issues"""
    android_dir = os.path.join(config.PROJECT_DIR, "android")
    
    if not os.path.exists(android_dir):
        return False, "Android directory not found. Run a build first to create it."
    
    try:
        build_gradle_path = os.path.join(android_dir, "build.gradle")
        
        # Backup existing file
        if os.path.exists(build_gradle_path):
            backup_path = build_gradle_path + ".backup"
            shutil.copy2(build_gradle_path, backup_path)
        
        # Write new Gradle config
        gradle_content = '''// Top-level build file where you can add configuration options common to all sub-projects/modules.

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
            url("$rootDir/../node_modules/react-native/android")
        }
        maven {
            url("$rootDir/../node_modules/jsc-android/dist")
        }
        google()
        mavenCentral()
        maven { url 'https://www.jitpack.io' }
    }
}
'''
        
        with open(build_gradle_path, 'w', encoding='utf-8') as f:
            f.write(gradle_content)
        
        # Update gradle.properties
        gradle_properties_path = os.path.join(android_dir, "gradle.properties")
        properties_content = '''# Project-wide Gradle settings.

org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.configureondemand=true

android.useAndroidX=true
android.enableJetifier=true

# Increase timeout for slow connections
systemProp.org.gradle.internal.http.connectionTimeout=180000
systemProp.org.gradle.internal.http.socketTimeout=180000
'''
        
        with open(gradle_properties_path, 'w', encoding='utf-8') as f:
            f.write(properties_content)
        
        return True, "Gradle configuration fixed successfully"
    except Exception as e:
        return False, f"Error fixing Gradle config: {e}"

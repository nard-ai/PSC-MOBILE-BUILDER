#!/usr/bin/env python3
"""
Simple configuration script for WebApp Wrapper
Runs inside Docker container - no GUI needed
"""

import json
import os
import sys

def read_current_config():
    """Read current configuration"""
    app_tsx_path = "/app/App.tsx"
    app_json_path = "/app/app.json"
    
    # Read URL from App.tsx
    current_url = ""
    if os.path.exists(app_tsx_path):
        with open(app_tsx_path, 'r') as f:
            content = f.read()
            for line in content.split('\n'):
                if 'APP_URL' in line and '=' in line:
                    current_url = line.split('=')[1].strip().strip("';\"")
                    break
    
    # Read name from app.json
    current_name = ""
    if os.path.exists(app_json_path):
        with open(app_json_path, 'r') as f:
            config = json.load(f)
            current_name = config.get('expo', {}).get('name', '')
    
    return current_url, current_name

def update_config(new_url, new_name):
    """Update configuration files"""
    app_tsx_path = "/app/App.tsx"
    app_json_path = "/app/app.json"
    
    success = True
    
    # Update App.tsx
    try:
        with open(app_tsx_path, 'r') as f:
            content = f.read()
        
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'APP_URL' in line and '=' in line:
                lines[i] = f"const APP_URL = '{new_url}';"
                break
        
        with open(app_tsx_path, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"✅ Updated App.tsx with URL: {new_url}")
    except Exception as e:
        print(f"❌ Failed to update App.tsx: {e}")
        success = False
    
    # Update app.json
    try:
        with open(app_json_path, 'r') as f:
            config = json.load(f)
        
        config['expo']['name'] = new_name
        if 'android' in config['expo']:
            config['expo']['android']['label'] = new_name
        
        with open(app_json_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"✅ Updated app.json with name: {new_name}")
    except Exception as e:
        print(f"❌ Failed to update app.json: {e}")
        success = False
    
    return success

def main():
    if len(sys.argv) == 1:
        # Interactive mode
        print("🔧 WebApp Wrapper Configuration")
        print("=" * 40)
        
        current_url, current_name = read_current_config()
        
        print(f"Current URL: {current_url}")
        print(f"Current Name: {current_name}")
        print()
        
        new_url = input("Enter new app URL (or press Enter to keep current): ").strip()
        if not new_url:
            new_url = current_url
        
        new_name = input("Enter new app name (or press Enter to keep current): ").strip()
        if not new_name:
            new_name = current_name
        
        if not new_url:
            print("❌ App URL cannot be empty!")
            return 1
        
        if not new_name:
            print("❌ App name cannot be empty!")
            return 1
        
        print("\n⚙️  Updating configuration...")
        if update_config(new_url, new_name):
            print("\n✅ Configuration updated successfully!")
            print(f"   URL: {new_url}")
            print(f"   Name: {new_name}")
            return 0
        else:
            print("\n❌ Configuration update failed!")
            return 1
    
    elif len(sys.argv) == 3:
        # Command line mode
        new_url = sys.argv[1]
        new_name = sys.argv[2]
        
        if update_config(new_url, new_name):
            print("✅ Configuration updated successfully!")
            return 0
        else:
            print("❌ Configuration update failed!")
            return 1
    
    else:
        print("Usage:")
        print("  python3 configure_app.py                    # Interactive mode")
        print("  python3 configure_app.py <url> <name>       # Command line mode")
        return 1

if __name__ == "__main__":
    sys.exit(main())
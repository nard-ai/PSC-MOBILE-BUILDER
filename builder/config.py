"""
Configuration module for PSC Mobile Builder
Handles paths, settings, and EXPO_TOKEN management
"""
import os
import json

# Get the base directory (parent of builder folder)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILDER_DIR = os.path.dirname(os.path.abspath(__file__))

# Runtime paths
RUNTIME_DIR = os.path.join(BASE_DIR, "runtime")
PYTHON_DIR = os.path.join(RUNTIME_DIR, "python")
NODE_DIR = os.path.join(RUNTIME_DIR, "node")

# Project paths (React Native project)
PROJECT_DIR = BASE_DIR  # The WebAppWrapperExpo folder is the project
APP_TSX_PATH = os.path.join(PROJECT_DIR, "App.tsx")
APP_JSON_PATH = os.path.join(PROJECT_DIR, "app.json")
ASSETS_DIR = os.path.join(PROJECT_DIR, "assets")

# Output paths
BUILDS_DIR = os.path.join(BASE_DIR, "builds")
LOGS_DIR = os.path.join(BASE_DIR, "logs")

# Configuration file for storing EXPO_TOKEN and other settings
CONFIG_FILE = os.path.join(BASE_DIR, "builder_config.json")

# Ensure output directories exist
os.makedirs(BUILDS_DIR, exist_ok=True)
os.makedirs(LOGS_DIR, exist_ok=True)


def get_eas_cli_path():
    """Get the path to portable EAS CLI"""
    eas_cmd = os.path.join(NODE_DIR, "eas.cmd")
    if os.path.exists(eas_cmd):
        return eas_cmd
    # Fallback to system EAS if portable not found
    import shutil
    return shutil.which("eas")


def get_node_path():
    """Get the path to portable Node.js"""
    node_exe = os.path.join(NODE_DIR, "node.exe")
    if os.path.exists(node_exe):
        return node_exe
    # Fallback to system Node
    import shutil
    return shutil.which("node")


def load_config():
    """Load saved configuration from file"""
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def save_config(config_data):
    """Save configuration to file"""
    try:
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(config_data, f, indent=2)
        return True
    except Exception as e:
        print(f"Error saving config: {e}")
        return False


def get_expo_token():
    """Get EXPO_TOKEN from environment or saved config"""
    # First check environment variable
    token = os.environ.get("EXPO_TOKEN")
    if token:
        return token
    
    # Then check saved config
    config = load_config()
    return config.get("expo_token", "")


def set_expo_token(token):
    """Save EXPO_TOKEN to config file and set in environment"""
    config = load_config()
    config["expo_token"] = token
    save_config(config)
    os.environ["EXPO_TOKEN"] = token


def is_first_run():
    """Check if this is the first run (no EXPO_TOKEN configured)"""
    return not get_expo_token()


def get_runtime_env():
    """Get environment variables with portable runtime paths"""
    env = os.environ.copy()
    
    # Add Node.js to PATH
    if os.path.exists(NODE_DIR):
        current_path = env.get("PATH", "")
        env["PATH"] = f"{NODE_DIR};{current_path}"
    
    # Add EXPO_TOKEN
    token = get_expo_token()
    if token:
        env["EXPO_TOKEN"] = token
    
    return env


# Validate paths on import
def validate_runtime():
    """Check if runtime is properly set up"""
    issues = []
    
    if not os.path.exists(RUNTIME_DIR):
        issues.append("Runtime directory not found. Run setup scripts first.")
    
    if not os.path.exists(PYTHON_DIR):
        issues.append("Python runtime not found.")
    
    if not os.path.exists(NODE_DIR):
        issues.append("Node.js runtime not found.")
    
    eas_path = get_eas_cli_path()
    if not eas_path:
        issues.append("EAS CLI not found.")
    
    return issues

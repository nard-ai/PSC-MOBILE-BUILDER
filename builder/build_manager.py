"""
Build Manager for PSC Mobile Builder
Handles EAS build execution and APK downloads
"""
import os
import re
import subprocess
import threading
import queue
import time
import requests
from datetime import datetime
from . import config


class BuildManager:
    """Manages EAS build process with log streaming"""
    
    def __init__(self):
        self.process = None
        self.log_queue = queue.Queue()
        self.is_building = False
        self.build_thread = None
        self.apk_url = None
        self.build_id = None
    
    def start_build(self):
        """Start an EAS build in a background thread"""
        if self.is_building:
            return False, "Build already in progress"
        
        # Clear previous state
        self.log_queue = queue.Queue()
        self.apk_url = None
        self.build_id = None
        
        # Validate runtime
        issues = config.validate_runtime()
        if issues:
            return False, f"Runtime issues: {'; '.join(issues)}"
        
        # Check EXPO_TOKEN
        if not config.get_expo_token():
            return False, "EXPO_TOKEN not configured. Please set it in Settings."
        
        self.is_building = True
        self.build_thread = threading.Thread(target=self._run_build, daemon=True)
        self.build_thread.start()
        
        return True, "Build started"
    
    def _run_build(self):
        """Execute the EAS build command"""
        try:
            self._log(f"[{self._timestamp()}] Starting EAS build...\n")
            self._log(f"[{self._timestamp()}] Project: {config.PROJECT_DIR}\n\n")
            
            eas_cli = config.get_eas_cli_path()
            if not eas_cli:
                self._log("[ERROR] EAS CLI not found!\n")
                self.is_building = False
                return
            
            self._log(f"Using EAS CLI: {eas_cli}\n")
            
            command = [
                eas_cli,
                "build",
                "--platform", "android",
                "--profile", "production",
                "--non-interactive"
            ]
            
            env = config.get_runtime_env()
            
            self.process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                cwd=config.PROJECT_DIR,
                env=env,
                bufsize=1
            )
            
            # Stream output
            for line in iter(self.process.stdout.readline, ''):
                if line:
                    self._log(line)
                    # Try to capture APK URL
                    self._parse_for_apk_url(line)
            
            self.process.wait()
            
            if self.process.returncode == 0:
                self._log(f"\n[{self._timestamp()}] Build completed successfully!\n")
                if self.apk_url:
                    self._log(f"\nAPK Download URL: {self.apk_url}\n")
            else:
                self._log(f"\n[{self._timestamp()}] Build failed (exit code: {self.process.returncode})\n")
        
        except Exception as e:
            self._log(f"\n[ERROR] {str(e)}\n")
        
        finally:
            self.is_building = False
            self.process = None
    
    def _parse_for_apk_url(self, line):
        """Try to extract APK download URL from build output"""
        # EAS outputs URLs like: https://expo.dev/artifacts/eas/...
        url_patterns = [
            r'(https://expo\.dev/artifacts/eas/[^\s]+\.apk)',
            r'(https://expo\.dev/artifacts/[^\s]+)',
            r'Build artifact: (https://[^\s]+)',
            r'Download: (https://[^\s]+\.apk)',
        ]
        
        for pattern in url_patterns:
            match = re.search(pattern, line)
            if match:
                self.apk_url = match.group(1)
                break
        
        # Also try to capture build ID
        build_id_match = re.search(r'Build ID: ([a-f0-9-]+)', line)
        if build_id_match:
            self.build_id = build_id_match.group(1)
    
    def _log(self, message):
        """Add message to log queue"""
        self.log_queue.put(message)
    
    def _timestamp(self):
        """Get current timestamp"""
        return datetime.now().strftime("%H:%M:%S")
    
    def get_logs(self):
        """Get all pending log messages"""
        logs = []
        while not self.log_queue.empty():
            try:
                logs.append(self.log_queue.get_nowait())
            except queue.Empty:
                break
        return ''.join(logs)
    
    def cancel_build(self):
        """Cancel the current build"""
        if self.process:
            self.process.terminate()
            self._log("\n[CANCELLED] Build was cancelled by user.\n")
            self.is_building = False
            return True
        return False
    
    def download_apk(self, url=None):
        """Download APK from given URL or last known URL"""
        target_url = url or self.apk_url
        
        if not target_url:
            return False, "No APK URL available"
        
        try:
            self._log(f"\n[{self._timestamp()}] Downloading APK...\n")
            self._log(f"URL: {target_url}\n")
            
            # Create builds folder if needed
            os.makedirs(config.BUILDS_DIR, exist_ok=True)
            
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"app_{timestamp}.apk"
            filepath = os.path.join(config.BUILDS_DIR, filename)
            
            # Download with progress
            response = requests.get(target_url, stream=True)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(filepath, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size:
                            progress = (downloaded / total_size) * 100
                            self._log(f"\rDownloading: {progress:.1f}%")
            
            self._log(f"\n\n[{self._timestamp()}] APK saved to: {filepath}\n")
            return True, filepath
        
        except Exception as e:
            self._log(f"\n[ERROR] Download failed: {e}\n")
            return False, str(e)
    
    def get_build_status(self):
        """Get current build status"""
        return {
            'is_building': self.is_building,
            'apk_url': self.apk_url,
            'build_id': self.build_id
        }


# Global build manager instance
build_manager = BuildManager()

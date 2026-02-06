"""
PSC Mobile Builder - Flask Web Application
Main application with all routes and endpoints
"""
import os
import time
import webbrowser
import threading
from flask import Flask, render_template, request, jsonify, send_from_directory, Response

from . import config
from . import project_manager
from .build_manager import build_manager

# Create Flask app
app = Flask(__name__,
            template_folder=os.path.join(os.path.dirname(__file__), 'templates'),
            static_folder=os.path.join(os.path.dirname(__file__), 'static'))

app.config['SECRET_KEY'] = 'psc-mobile-builder-secret-key'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB max upload


# ============== PAGES ==============

@app.route('/')
def index():
    """Main page with build form"""
    # Check if first run (no EXPO_TOKEN)
    if config.is_first_run():
        return render_template('setup.html')
    
    # Get current configuration
    current_config = project_manager.get_current_config()
    runtime_issues = config.validate_runtime()
    
    return render_template('index.html',
                          config=current_config,
                          runtime_issues=runtime_issues)


@app.route('/settings')
def settings():
    """Settings page"""
    saved_config = config.load_config()
    return render_template('settings.html',
                          expo_token=config.get_expo_token(),
                          saved_config=saved_config)


# ============== API ENDPOINTS ==============

@app.route('/api/save-token', methods=['POST'])
def save_token():
    """Save EXPO_TOKEN"""
    data = request.get_json()
    token = data.get('token', '').strip()
    
    if not token:
        return jsonify({'success': False, 'error': 'Token cannot be empty'})
    
    config.set_expo_token(token)
    return jsonify({'success': True, 'message': 'Token saved successfully'})


@app.route('/api/save-config', methods=['POST'])
def save_config_endpoint():
    """Save project configuration"""
    data = request.get_json()
    
    app_url = data.get('app_url', '').strip()
    app_name = data.get('app_name', '').strip()
    package_id = data.get('package_id', '').strip()
    
    if not app_url:
        return jsonify({'success': False, 'error': 'App URL is required'})
    
    if not app_name:
        return jsonify({'success': False, 'error': 'App Name is required'})
    
    success, results = project_manager.save_all_config(app_url, app_name, package_id)
    
    return jsonify({
        'success': success,
        'results': results
    })


@app.route('/api/upload-icon', methods=['POST'])
def upload_icon():
    """Upload custom icon"""
    if 'icon' not in request.files:
        return jsonify({'success': False, 'error': 'No icon file provided'})
    
    file = request.files['icon']
    if file.filename == '':
        return jsonify({'success': False, 'error': 'No file selected'})
    
    # Save to temp location first
    temp_path = os.path.join(config.BUILDS_DIR, 'temp_icon.png')
    file.save(temp_path)
    
    # Update icon
    success, message = project_manager.update_icon(temp_path)
    
    # Clean up temp file
    if os.path.exists(temp_path):
        os.remove(temp_path)
    
    return jsonify({'success': success, 'message': message})


@app.route('/api/validate', methods=['GET'])
def validate_config():
    """Validate current configuration"""
    icon_errors = project_manager.validate_icon_paths()
    runtime_issues = config.validate_runtime()
    
    return jsonify({
        'valid': len(icon_errors) == 0 and len(runtime_issues) == 0,
        'icon_errors': icon_errors,
        'runtime_issues': runtime_issues
    })


@app.route('/api/build/start', methods=['POST'])
def start_build():
    """Start an EAS build"""
    # Validate first
    icon_errors = project_manager.validate_icon_paths()
    if icon_errors:
        return jsonify({
            'success': False,
            'error': f"Icon validation failed: {'; '.join(icon_errors)}"
        })
    
    success, message = build_manager.start_build()
    return jsonify({'success': success, 'message': message})


@app.route('/api/build/status', methods=['GET'])
def build_status():
    """Get current build status"""
    return jsonify(build_manager.get_build_status())


@app.route('/api/build/logs', methods=['GET'])
def build_logs():
    """Get pending build logs (for polling)"""
    logs = build_manager.get_logs()
    status = build_manager.get_build_status()
    return jsonify({
        'logs': logs,
        **status
    })


@app.route('/api/build/stream')
def build_logs_stream():
    """Server-Sent Events stream for build logs"""
    def generate():
        while True:
            logs = build_manager.get_logs()
            if logs:
                # Escape for SSE
                data = logs.replace('\n', '\\n').replace('\r', '')
                yield f"data: {data}\n\n"
            
            status = build_manager.get_build_status()
            if not status['is_building']:
                yield f"event: done\ndata: Build finished\n\n"
                break
            
            time.sleep(0.5)
    
    return Response(generate(), mimetype='text/event-stream')


@app.route('/api/build/cancel', methods=['POST'])
def cancel_build():
    """Cancel current build"""
    success = build_manager.cancel_build()
    return jsonify({'success': success})


@app.route('/api/build/download', methods=['POST'])
def download_apk():
    """Download APK from URL"""
    data = request.get_json()
    url = data.get('url')
    
    success, result = build_manager.download_apk(url)
    return jsonify({'success': success, 'result': result})


@app.route('/api/gradle/fix', methods=['POST'])
def fix_gradle():
    """Fix Gradle configuration"""
    success, message = project_manager.fix_gradle_config()
    return jsonify({'success': success, 'message': message})


@app.route('/api/config', methods=['GET'])
def get_config():
    """Get current project configuration"""
    return jsonify(project_manager.get_current_config())


# ============== FILE SERVING ==============

@app.route('/builds/<path:filename>')
def download_build(filename):
    """Serve downloaded APK files"""
    return send_from_directory(config.BUILDS_DIR, filename, as_attachment=True)


@app.route('/api/builds', methods=['GET'])
def list_builds():
    """List all downloaded builds"""
    builds = []
    if os.path.exists(config.BUILDS_DIR):
        for file in os.listdir(config.BUILDS_DIR):
            if file.endswith('.apk'):
                filepath = os.path.join(config.BUILDS_DIR, file)
                builds.append({
                    'filename': file,
                    'size': os.path.getsize(filepath),
                    'modified': os.path.getmtime(filepath)
                })
    
    # Sort by date, newest first
    builds.sort(key=lambda x: x['modified'], reverse=True)
    return jsonify(builds)


# ============== MAIN ==============

def open_browser():
    """Open browser after short delay"""
    time.sleep(1.5)
    webbrowser.open('http://localhost:5000')


def run_server(open_browser_on_start=True):
    """Run the Flask development server"""
    if open_browser_on_start:
        threading.Thread(target=open_browser, daemon=True).start()
    
    print("\n" + "="*50)
    print("   PSC Mobile Builder")
    print("="*50)
    print(f"\n   Open in browser: http://localhost:5000")
    print("\n   Press Ctrl+C to stop the server")
    print("="*50 + "\n")
    
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)


if __name__ == '__main__':
    run_server()

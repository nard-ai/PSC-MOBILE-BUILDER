#!/usr/bin/env python
"""
PSC Mobile Builder - Main Entry Point

Run this script to start the Flask web UI:
    python -m builder.main

Or use START-BUILDER.bat for portable installation.
"""
import sys
import os

# Ensure builder package is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from builder.app import run_server


def main():
    """Main entry point"""
    print("\n" + "="*50)
    print("   PSC Mobile Builder - Starting...")
    print("="*50 + "\n")
    
    # Check if we have the runtime
    from builder import config
    issues = config.validate_runtime()
    
    if issues:
        print("WARNING: Runtime issues detected:")
        for issue in issues:
            print(f"  - {issue}")
        print("\nThe builder may not work correctly.")
        print("Run the setup scripts in setup/ folder first.\n")
    
    # Check for EXPO_TOKEN
    if config.is_first_run():
        print("NOTE: EXPO_TOKEN not configured.")
        print("You will be prompted to enter it on first launch.\n")
    
    # Start the server
    run_server(open_browser_on_start=True)


if __name__ == '__main__':
    main()

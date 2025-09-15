#!/usr/bin/env python3
"""
Entry point for the restructured Student Attendance System.
This file imports and runs the Flask application from the backend directory.
"""

import sys
import os

# Add the backend directory to the Python path
backend_path = os.path.join(os.path.dirname(__file__), 'backend')
sys.path.insert(0, backend_path)

# Import the app from the backend directory
from app import app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
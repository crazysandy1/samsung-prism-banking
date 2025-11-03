# PythonAnywhere WSGI Entry Point
# This file is required by PythonAnywhere for Flask applications

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

# Import the Flask application
from app import app as application

# PythonAnywhere will automatically call application.run()
# No need to add if __name__ == "__main__" block here

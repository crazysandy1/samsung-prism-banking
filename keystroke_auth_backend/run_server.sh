#!/bin/bash
# Shell script to run the Keystroke Dynamics Authentication Backend
# This script activates the virtual environment and starts the Flask server

echo "==============================================="
echo "Keystroke Dynamics Authentication Backend"
echo "==============================================="
echo

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "ERROR: Virtual environment not found!"
    echo "Please run setup.py first to create the environment."
    echo
    echo "Usage: python setup.py"
    exit 1
fi

echo "Activating virtual environment..."
source venv/bin/activate

echo
echo "Starting Flask server..."
echo "Server will be available at: http://localhost:5000"
echo "Press Ctrl+C to stop the server"
echo

python app.py

echo
echo "Server stopped."

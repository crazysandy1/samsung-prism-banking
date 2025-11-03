@echo off
REM Batch script to run the Keystroke Dynamics Authentication Backend
REM This script activates the virtual environment and starts the Flask server

echo ===============================================
echo Keystroke Dynamics Authentication Backend
echo ===============================================
echo.

REM Check if virtual environment exists
if not exist "venv" (
    echo ERROR: Virtual environment not found!
    echo Please run setup.py first to create the environment.
    echo.
    echo Usage: python setup.py
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Starting Flask server...
echo Server will be available at: http://localhost:5000
echo Press Ctrl+C to stop the server
echo.

python app.py

echo.
echo Server stopped.
pause

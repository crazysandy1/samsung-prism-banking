@echo off
REM Samsung Prism Multi-Agent System - Windows Batch Runner

echo Samsung Prism Multi-Agent System
echo ================================

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.8 or higher from https://python.org
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo Error: Failed to create virtual environment
        pause
        exit /b 1
    )
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo Error: Failed to activate virtual environment
    pause
    exit /b 1
)

REM Install requirements if needed
if not exist "venv\Lib\site-packages\fastapi" (
    echo Installing requirements...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo Error: Failed to install requirements
        pause
        exit /b 1
    )
)

REM Check if .env file exists
if not exist ".env" (
    echo Warning: .env file not found
    echo Please copy .env.example to .env and configure it
    if exist ".env.example" (
        echo Copying .env.example to .env...
        copy ".env.example" ".env"
        echo Please edit .env file with your configuration
        pause
    )
)

REM Run the application
echo Starting Samsung Prism Multi-Agent System...
echo API will be available at: http://localhost:8000
echo API Documentation at: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo.

python main.py

pause

@echo off
REM Keystroke Authentication Backend - Windows Deployment Script
REM This script provides automated deployment options for Windows

setlocal enabledelayedexpansion

REM Colors (using color codes)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "RESET=[0m"

REM Configuration
set APP_NAME=keystroke-auth
set APP_PORT=5000
set DOCKER_IMAGE=keystroke-auth:latest

:print_header
echo.
echo ================================================
echo   Keystroke Authentication Backend Deployment
echo ================================================
echo.
goto :eof

:print_success
echo ✅ %~1
goto :eof

:print_error
echo ❌ %~1
goto :eof

:print_warning
echo ⚠️  %~1
goto :eof

:print_info
echo ℹ️  %~1
goto :eof

:check_dependencies
call :print_info "Checking dependencies..."

REM Check if app.py exists
if not exist "app.py" (
    call :print_error "app.py not found. Please run this script from the keystroke_auth_backend directory."
    exit /b 1
)

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Python is not installed. Please install Python 3.7 or higher."
    exit /b 1
)

REM Check pip
pip --version >nul 2>&1
if errorlevel 1 (
    call :print_error "pip is not installed. Please install pip."
    exit /b 1
)

call :print_success "Dependencies check passed"
goto :eof

:setup_virtual_environment
call :print_info "Setting up Python virtual environment..."

if not exist "venv" (
    python -m venv venv
    call :print_success "Virtual environment created"
) else (
    call :print_warning "Virtual environment already exists"
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install dependencies
pip install -r requirements.txt
call :print_success "Dependencies installed"
goto :eof

:create_dockerfile
call :print_info "Creating Dockerfile..."

(
echo FROM python:3.11-slim
echo.
echo WORKDIR /app
echo.
echo # Install system dependencies
echo RUN apt-get update ^&^& apt-get install -y \
echo     gcc \
echo     ^&^& rm -rf /var/lib/apt/lists/*
echo.
echo # Copy requirements first for better caching
echo COPY requirements.txt .
echo RUN pip install --no-cache-dir -r requirements.txt
echo.
echo # Copy application code
echo COPY . .
echo.
echo # Create model directory
echo RUN mkdir -p user_models
echo.
echo # Expose port
echo EXPOSE 5000
echo.
echo # Set environment variables
echo ENV FLASK_ENV=production
echo ENV FLASK_HOST=0.0.0.0
echo ENV FLASK_PORT=5000
echo.
echo # Run the application
echo CMD ["python", "app.py"]
) > Dockerfile

call :print_success "Dockerfile created"
goto :eof

:create_docker_compose
call :print_info "Creating docker-compose.yml..."

(
echo version: '3.8'
echo.
echo services:
echo   keystroke-auth:
echo     build: .
echo     ports:
echo       - "5000:5000"
echo     volumes:
echo       - ./user_models:/app/user_models
echo     environment:
echo       - FLASK_ENV=production
echo       - FLASK_DEBUG=false
echo     restart: unless-stopped
) > docker-compose.yml

call :print_success "docker-compose.yml created"
goto :eof

:deploy_local
call :print_info "Deploying locally..."

REM Setup virtual environment
call :setup_virtual_environment

REM Create necessary directories
if not exist "user_models" mkdir user_models

REM Set environment variables
set FLASK_ENV=development
set FLASK_HOST=0.0.0.0
set FLASK_PORT=5000

call :print_success "Local deployment ready"
call :print_info "Starting server..."
python app.py
goto :eof

:deploy_docker
call :print_info "Deploying with Docker..."

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not installed. Please install Docker Desktop."
    exit /b 1
)

REM Create Dockerfile if it doesn't exist
if not exist "Dockerfile" call :create_dockerfile

REM Create docker-compose.yml if it doesn't exist
if not exist "docker-compose.yml" call :create_docker_compose

REM Build and run
docker-compose up -d --build

call :print_success "Docker deployment completed"
call :print_info "Service is running on http://localhost:5000"
call :print_info "Check logs with: docker-compose logs -f"
goto :eof

:deploy_production
call :print_info "Setting up production deployment..."

REM Create necessary directories
if not exist "user_models" mkdir user_models
if not exist "logs" mkdir logs

call :print_success "Production directories created"
call :print_info "For production deployment on Windows:"
call :print_info "  1. Consider using IIS with wfastcgi"
call :print_info "  2. Or use Windows Service with NSSM"
call :print_info "  3. Or deploy to Azure App Service"
goto :eof

:show_menu
echo.
echo Choose deployment option:
echo 1^) Local Development ^(with virtual environment^)
echo 2^) Docker Deployment
echo 3^) Production Server Setup
echo 4^) Create Docker files only
echo 5^) Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto deploy_local
if "%choice%"=="2" goto deploy_docker
if "%choice%"=="3" (
    call :setup_virtual_environment
    call :deploy_production
    goto :eof
)
if "%choice%"=="4" (
    call :create_dockerfile
    call :create_docker_compose
    call :print_success "Docker files created. Run 'docker-compose up -d' to deploy."
    goto :eof
)
if "%choice%"=="5" (
    call :print_info "Goodbye!"
    goto :eof
)

call :print_error "Invalid choice. Please select 1-5."
goto show_menu

:main
call :print_header
call :check_dependencies
call :show_menu

:end
pause

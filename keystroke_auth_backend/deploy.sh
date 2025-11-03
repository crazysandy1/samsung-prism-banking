#!/bin/bash
# Keystroke Authentication Backend - Quick Deployment Script
# This script provides automated deployment options

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="keystroke-auth"
APP_PORT=5000
DOCKER_IMAGE="keystroke-auth:latest"

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Keystroke Authentication Backend Deployment${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_dependencies() {
    print_info "Checking dependencies..."

    # Check if we're in the right directory
    if [ ! -f "app.py" ]; then
        print_error "app.py not found. Please run this script from the keystroke_auth_backend directory."
        exit 1
    fi

    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3.7 or higher."
        exit 1
    fi

    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed. Please install pip3."
        exit 1
    fi

    print_success "Dependencies check passed"
}

setup_virtual_environment() {
    print_info "Setting up Python virtual environment..."

    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_warning "Virtual environment already exists"
    fi

    # Activate virtual environment
    source venv/bin/activate

    # Install dependencies
    pip install -r requirements.txt
    print_success "Dependencies installed"
}

create_dockerfile() {
    print_info "Creating Dockerfile..."

    cat > Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create model directory
RUN mkdir -p user_models

# Expose port
EXPOSE 5000

# Set environment variables
ENV FLASK_ENV=production
ENV FLASK_HOST=0.0.0.0
ENV FLASK_PORT=5000

# Run the application
CMD ["python", "app.py"]
EOF

    print_success "Dockerfile created"
}

create_docker_compose() {
    print_info "Creating docker-compose.yml..."

    cat > docker-compose.yml << EOF
version: '3.8'

services:
  keystroke-auth:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./user_models:/app/user_models
    environment:
      - FLASK_ENV=production
      - FLASK_DEBUG=false
    restart: unless-stopped
EOF

    print_success "docker-compose.yml created"
}

deploy_local() {
    print_info "Deploying locally..."

    # Setup virtual environment
    setup_virtual_environment

    # Create necessary directories
    mkdir -p user_models

    # Set environment variables
    export FLASK_ENV=development
    export FLASK_HOST=0.0.0.0
    export FLASK_PORT=5000

    print_success "Local deployment ready"
    print_info "Starting server..."
    python app.py
}

deploy_docker() {
    print_info "Deploying with Docker..."

    # Create Dockerfile if it doesn't exist
    if [ ! -f "Dockerfile" ]; then
        create_dockerfile
    fi

    # Create docker-compose.yml if it doesn't exist
    if [ ! -f "docker-compose.yml" ]; then
        create_docker_compose
    fi

    # Build and run
    docker-compose up -d --build

    print_success "Docker deployment completed"
    print_info "Service is running on http://localhost:5000"
    print_info "Check logs with: docker-compose logs -f"
}

deploy_production() {
    print_info "Setting up production deployment..."

    # Create necessary directories
    mkdir -p user_models
    mkdir -p logs

    # Create systemd service file
    cat > keystroke-auth.service << EOF
[Unit]
Description=Keystroke Authentication Backend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=FLASK_ENV=production
Environment=FLASK_HOST=0.0.0.0
Environment=FLASK_PORT=5000
ExecStart=$(pwd)/venv/bin/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    print_success "Production service file created"
    print_info "To install as system service:"
    print_info "  sudo cp keystroke-auth.service /etc/systemd/system/"
    print_info "  sudo systemctl daemon-reload"
    print_info "  sudo systemctl enable keystroke-auth"
    print_info "  sudo systemctl start keystroke-auth"
}

show_menu() {
    echo
    echo "Choose deployment option:"
    echo "1) Local Development (with virtual environment)"
    echo "2) Docker Deployment"
    echo "3) Production Server Setup"
    echo "4) Create Docker files only"
    echo "5) Exit"
    echo
    read -p "Enter your choice (1-5): " choice

    case $choice in
        1)
            deploy_local
            ;;
        2)
            deploy_docker
            ;;
        3)
            setup_virtual_environment
            deploy_production
            ;;
        4)
            create_dockerfile
            create_docker_compose
            print_success "Docker files created. Run 'docker-compose up -d' to deploy."
            ;;
        5)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please select 1-5."
            show_menu
            ;;
    esac
}

# Main execution
main() {
    print_header
    check_dependencies
    show_menu
}

# Run main function
main "$@"

#!/bin/bash
# PythonAnywhere Deployment Script for Keystroke Authentication Backend
# Run this script on PythonAnywhere to set up your application

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  PythonAnywhere Keystroke Auth Deployment${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_pythonanywhere() {
    print_info "Checking PythonAnywhere environment..."

    if [ -z "$PYTHONANYWHERE_DOMAIN" ]; then
        print_warning "PYTHONANYWHERE_DOMAIN not set. Make sure you're on PythonAnywhere."
        print_info "Continuing with deployment anyway..."
    else
        print_success "PythonAnywhere environment detected: $PYTHONANYWHERE_DOMAIN"
    fi
}

setup_virtualenv() {
    print_info "Setting up Python virtual environment..."

    # Create virtual environment if it doesn't exist
    if [ ! -d "keystroke_env" ]; then
        python3.11 -m venv keystroke_env
        print_success "Virtual environment created"
    else
        print_warning "Virtual environment already exists"
    fi

    # Activate virtual environment
    source keystroke_env/bin/activate

    # Upgrade pip
    pip install --upgrade pip

    # Install dependencies
    pip install -r requirements-pythonanywhere.txt

    print_success "Dependencies installed"
}

create_directories() {
    print_info "Creating necessary directories..."

    mkdir -p user_models
    mkdir -p static
    mkdir -p templates

    print_success "Directories created"
}

setup_environment() {
    print_info "Setting up environment configuration..."

    # Copy PythonAnywhere environment file
    if [ -f ".env.pythonanywhere" ]; then
        cp .env.pythonanywhere .env
        print_success "Environment file configured"
    else
        print_warning "PythonAnywhere environment file not found"
    fi

    # Set PythonAnywhere-specific environment variables
    export FLASK_ENV=production
    export FLASK_DEBUG=false
    export ENABLE_CORS=true

    if [ ! -z "$PYTHONANYWHERE_DOMAIN" ]; then
        export PYTHONANYWHERE_DOMAIN=$PYTHONANYWHERE_DOMAIN
    fi

    print_success "Environment variables set"
}

test_application() {
    print_info "Testing application..."

    # Activate virtual environment
    source keystroke_env/bin/activate

    # Test import
    python -c "from app import app; print('✅ Flask app imports successfully')"

    # Test basic functionality
    python -c "
from app import app
with app.app_context():
    from services.health_service import get_health_status
    print('✅ Application context works')
"

    print_success "Application tests passed"
}

create_wsgi_file() {
    print_info "Ensuring WSGI file is properly configured..."

    if [ ! -f "flask_app.py" ]; then
        print_error "flask_app.py not found!"
        exit 1
    fi

    print_success "WSGI file is ready"
}

print_deployment_instructions() {
    echo
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}        DEPLOYMENT INSTRUCTIONS${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
    print_info "Follow these steps in PythonAnywhere dashboard:"
    echo
    echo "1. 🌐 Go to Web tab"
    echo "2. ➕ Click 'Add a new web app'"
    echo "3. 🔧 Choose 'Flask' and 'Python 3.11'"
    echo "4. 📁 Set source code path to:"
    echo "   /home/$(whoami)/Samsung_prism/keystroke_auth_backend"
    echo "5. 📄 Set WSGI configuration file to:"
    echo "   flask_app.py"
    echo "6. 🔄 Set virtualenv path to:"
    echo "   /home/$(whoami)/keystroke_env"
    echo "7. ⚙️  Set environment variables:"
    echo "   FLASK_ENV=production"
    echo "   FLASK_DEBUG=false"
    echo "   ENABLE_CORS=true"
    echo "8. 🔄 Click 'Reload' to deploy"
    echo
    print_success "Your API will be available at:"
    if [ ! -z "$PYTHONANYWHERE_DOMAIN" ]; then
        echo "   https://$PYTHONANYWHERE_DOMAIN/"
    else
        echo "   https://yourusername.pythonanywhere.com/"
    fi
    echo
    print_info "API Endpoints:"
    echo "   Health: /health"
    echo "   Train:  /train"
    echo "   Predict: /predict"
    echo "   User Info: /user/<id>/info"
    echo
}

main() {
    print_header

    check_pythonanywhere
    setup_virtualenv
    create_directories
    setup_environment
    test_application
    create_wsgi_file

    print_success "PythonAnywhere deployment setup completed!"
    print_deployment_instructions
}

# Run main function
main "$@"

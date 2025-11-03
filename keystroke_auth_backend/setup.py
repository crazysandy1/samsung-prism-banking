#!/usr/bin/env python3
"""
Setup Script for Keystroke Dynamics Authentication Backend

This script helps set up the Flask backend application with all necessary dependencies.

Usage: python setup.py
"""

import os
import sys
import subprocess
import platform


def print_header():
    """Print setup header."""
    print("=" * 60)
    print("Keystroke Dynamics Authentication Backend Setup")
    print("=" * 60)
    print()


def check_python_version():
    """Check if Python version is compatible."""
    print("🔍 Checking Python version...")
    
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 7):
        print("❌ Python 3.7 or higher is required!")
        print(f"   Current version: {version.major}.{version.minor}.{version.micro}")
        return False
    
    print(f"✅ Python {version.major}.{version.minor}.{version.micro} - Compatible")
    return True


def check_pip():
    """Check if pip is available."""
    print("🔍 Checking pip availability...")
    
    try:
        subprocess.run([sys.executable, "-m", "pip", "--version"], 
                      check=True, capture_output=True)
        print("✅ pip is available")
        return True
    except subprocess.CalledProcessError:
        print("❌ pip is not available!")
        return False


def create_virtual_environment():
    """Create a virtual environment."""
    print("🔍 Setting up virtual environment...")
    
    venv_name = "venv"
    
    if os.path.exists(venv_name):
        print(f"⚠️  Virtual environment '{venv_name}' already exists")
        response = input("Do you want to recreate it? (y/N): ").strip().lower()
        if response == 'y':
            print(f"🗑️  Removing existing virtual environment...")
            if platform.system() == "Windows":
                subprocess.run(["rmdir", "/s", "/q", venv_name], shell=True)
            else:
                subprocess.run(["rm", "-rf", venv_name])
        else:
            print(f"📁 Using existing virtual environment")
            return True
    
    try:
        print(f"📦 Creating virtual environment '{venv_name}'...")
        subprocess.run([sys.executable, "-m", "venv", venv_name], check=True)
        print(f"✅ Virtual environment created successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to create virtual environment: {e}")
        return False


def install_dependencies():
    """Install required dependencies."""
    print("🔍 Installing dependencies...")
    
    # Determine the correct python executable path
    if platform.system() == "Windows":
        python_exe = os.path.join("venv", "Scripts", "python.exe")
        pip_exe = os.path.join("venv", "Scripts", "pip.exe")
    else:
        python_exe = os.path.join("venv", "bin", "python")
        pip_exe = os.path.join("venv", "bin", "pip")
    
    # Check if requirements.txt exists
    if not os.path.exists("requirements.txt"):
        print("❌ requirements.txt not found!")
        return False
    
    try:
        print("📦 Installing packages from requirements.txt...")
        subprocess.run([pip_exe, "install", "-r", "requirements.txt"], check=True)
        print("✅ Dependencies installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install dependencies: {e}")
        return False


def create_directories():
    """Create necessary directories."""
    print("🔍 Creating directories...")
    
    directories = ["user_models"]
    
    for directory in directories:
        if not os.path.exists(directory):
            os.makedirs(directory)
            print(f"📁 Created directory: {directory}")
        else:
            print(f"📁 Directory already exists: {directory}")
    
    return True


def test_installation():
    """Test if the installation was successful."""
    print("🔍 Testing installation...")
    
    # Determine the correct python executable path
    if platform.system() == "Windows":
        python_exe = os.path.join("venv", "Scripts", "python.exe")
    else:
        python_exe = os.path.join("venv", "bin", "python")
    
    try:
        # Test importing key modules
        test_script = """
import flask
import sklearn
import numpy
import joblib
print("All required modules imported successfully!")
"""
        
        result = subprocess.run([python_exe, "-c", test_script], 
                              capture_output=True, text=True, check=True)
        print("✅ Installation test passed")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Installation test failed: {e}")
        print(f"   Error output: {e.stderr}")
        return False


def print_usage_instructions():
    """Print instructions for running the application."""
    print()
    print("🎉 Setup completed successfully!")
    print()
    print("📋 Next Steps:")
    print("=" * 40)
    
    if platform.system() == "Windows":
        print("1. Activate virtual environment:")
        print("   venv\\Scripts\\activate")
        print()
        print("2. Run the Flask application:")
        print("   python app.py")
    else:
        print("1. Activate virtual environment:")
        print("   source venv/bin/activate")
        print()
        print("2. Run the Flask application:")
        print("   python app.py")
    
    print()
    print("3. Test the API:")
    print("   python test_api.py")
    print()
    print("4. Access the API at:")
    print("   http://localhost:5000")
    print()
    print("📚 For more information, see README.md")


def main():
    """Run the complete setup process."""
    print_header()
    
    # Step 1: Check Python version
    if not check_python_version():
        return False
    print()
    
    # Step 2: Check pip
    if not check_pip():
        return False
    print()
    
    # Step 3: Create virtual environment
    if not create_virtual_environment():
        return False
    print()
    
    # Step 4: Install dependencies
    if not install_dependencies():
        return False
    print()
    
    # Step 5: Create directories
    if not create_directories():
        return False
    print()
    
    # Step 6: Test installation
    if not test_installation():
        return False
    print()
    
    # Step 7: Print usage instructions
    print_usage_instructions()
    
    return True


if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n⚠️  Setup interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error during setup: {e}")
        sys.exit(1)

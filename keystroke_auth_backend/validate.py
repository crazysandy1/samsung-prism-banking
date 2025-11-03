"""
Startup Validation Script for Keystroke Dynamics Authentication Backend

This script validates that all dependencies and configurations are properly set up
before starting the main application.
"""

import sys
import os

def validate_python_version():
    """Check if Python version is compatible."""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 7):
        print(f"❌ Python 3.7+ required, found {version.major}.{version.minor}")
        return False
    print(f"✅ Python {version.major}.{version.minor}.{version.micro}")
    return True

def validate_dependencies():
    """Check if all required dependencies are installed."""
    required_modules = [
        'flask',
        'flask_cors', 
        'sklearn',
        'numpy',
        'joblib'
    ]
    
    missing = []
    for module in required_modules:
        try:
            __import__(module)
            print(f"✅ {module}")
        except ImportError:
            missing.append(module)
            print(f"❌ {module}")
    
    if missing:
        print(f"\n❌ Missing dependencies: {', '.join(missing)}")
        print("Run: pip install -r requirements.txt")
        return False
    
    return True

def validate_configuration():
    """Check if configuration loads properly."""
    try:
        from config import get_config, FeatureExtractionConfig, ModelConfig
        config = get_config()
        print(f"✅ Configuration loaded")
        print(f"   Model directory: {config.MODEL_DIR}")
        print(f"   Min samples: {config.MIN_SAMPLES_FOR_TRAINING}")
        print(f"   Host: {config.HOST}:{config.PORT}")
        return True
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        return False

def validate_app_import():
    """Check if main app can be imported."""
    try:
        from app import app
        print("✅ Flask app imported successfully")
        return True
    except Exception as e:
        print(f"❌ App import error: {e}")
        return False

def create_directories():
    """Create necessary directories."""
    try:
        from config import get_config
        config = get_config()
        
        if not os.path.exists(config.MODEL_DIR):
            os.makedirs(config.MODEL_DIR)
            print(f"✅ Created directory: {config.MODEL_DIR}")
        else:
            print(f"✅ Directory exists: {config.MODEL_DIR}")
        return True
    except Exception as e:
        print(f"❌ Directory creation error: {e}")
        return False

def main():
    """Run all validation checks."""
    print("🔍 Validating Keystroke Dynamics Authentication Backend")
    print("=" * 55)
    
    checks = [
        ("Python Version", validate_python_version),
        ("Dependencies", validate_dependencies),
        ("Configuration", validate_configuration),
        ("App Import", validate_app_import),
        ("Directories", create_directories)
    ]
    
    all_passed = True
    for name, check_func in checks:
        print(f"\n📋 {name}:")
        if not check_func():
            all_passed = False
    
    print("\n" + "=" * 55)
    if all_passed:
        print("🎉 All validation checks passed!")
        print("✅ Ready to start the server")
        print("\nRun: python app.py")
        return True
    else:
        print("❌ Some validation checks failed")
        print("🔧 Please fix the issues above before starting the server")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

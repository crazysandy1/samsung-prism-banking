#!/usr/bin/env python3
"""
Setup script for Samsung Prism Multi-Agent System
"""

import os
import sys
import subprocess
import json

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 or higher is required")
        return False
    print(f"✅ Python {sys.version_info.major}.{sys.version_info.minor} is compatible")
    return True

def install_requirements():
    """Install required packages"""
    print("📦 Installing requirements...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("✅ Requirements installed successfully")
        return True
    except subprocess.CalledProcessError:
        print("❌ Failed to install requirements")
        return False

def check_firebase_config():
    """Check Firebase configuration"""
    print("🔥 Checking Firebase configuration...")
    
    env_file = ".env"
    env_example = ".env.example"
    
    if not os.path.exists(env_file):
        if os.path.exists(env_example):
            print(f"⚠️  {env_file} not found. Please copy {env_example} to {env_file} and configure it.")
        else:
            print(f"❌ Neither {env_file} nor {env_example} found")
        return False
    
    print(f"✅ {env_file} found")
    return True

def create_firebase_collections():
    """Create necessary Firebase collections structure"""
    print("🏗️  Setting up Firebase collections structure...")
    
    collections_structure = {
        "users": "User profile and authentication data",
        "user_balances": "User account balances",
        "transactions": "Transaction history",
        "user_cards": "User card information",
        "card_statements": "Credit card statements",
        "loan_applications": "Loan application records",
        "agent_interactions": "Agent interaction logs",
        "multi_agent_interactions": "Multi-agent system logs"
    }
    
    print("Required Firebase collections:")
    for collection, description in collections_structure.items():
        print(f"  📁 {collection}: {description}")
    
    print("\n💡 Make sure these collections exist in your Firebase Firestore database")
    return True

def run_tests():
    """Run basic system tests"""
    print("🧪 Running basic tests...")
    
    try:
        # Import and test basic functionality
        from config.firebase_config import firebase_config
        print("✅ Firebase config import successful")
        
        from agents.base_agent import BaseAgent, AgentResponse, UserQuery
        print("✅ Base agent import successful")
        
        from agents.multi_agent_system import MultiAgentSystem
        print("✅ Multi-agent system import successful")
        
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"❌ Test error: {e}")
        return False

def main():
    """Main setup function"""
    print("🚀 Samsung Prism Multi-Agent System Setup")
    print("=" * 50)
    
    success = True
    
    # Check Python version
    if not check_python_version():
        success = False
    
    # Install requirements
    if success and not install_requirements():
        success = False
    
    # Check Firebase config
    if success and not check_firebase_config():
        success = False
    
    # Setup Firebase collections
    if success:
        create_firebase_collections()
    
    # Run tests
    if success and not run_tests():
        success = False
    
    print("\n" + "=" * 50)
    if success:
        print("✅ Setup completed successfully!")
        print("\n📋 Next steps:")
        print("1. Configure your .env file with Firebase credentials")
        print("2. Ensure Firebase collections are created")
        print("3. Run: python main.py")
        print("4. Test API at: http://localhost:8000/docs")
    else:
        print("❌ Setup failed. Please check the errors above.")
    
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

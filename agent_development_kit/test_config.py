#!/usr/bin/env python3
"""
Samsung Prism Multi-Agent System Configuration Test
This script helps validate your configuration setup.
"""

import os
import asyncio
import sys
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

async def test_environment_variables():
    """Test if required environment variables are set"""
    print("🔍 Testing Environment Variables...")
    
    required_vars = {
        'FIREBASE_PROJECT_ID': 'Firebase project ID',
        'GEMINI_API_KEY': 'Gemini AI API key'
    }
    
    optional_vars = {
        'GOOGLE_APPLICATION_CREDENTIALS': 'Firebase service account credentials',
        'GOOGLE_CLOUD_PROJECT': 'Google Cloud project ID'
    }
    
    missing_required = []
    
    for var, description in required_vars.items():
        value = os.getenv(var)
        if value:
            print(f"  ✅ {var}: {'*' * min(len(value), 20)}")
        else:
            print(f"  ❌ {var}: Not set ({description})")
            missing_required.append(var)
    
    for var, description in optional_vars.items():
        value = os.getenv(var)
        if value:
            print(f"  ✅ {var}: {'*' * min(len(value), 20)}")
        else:
            print(f"  ⚠️  {var}: Not set ({description}) - Optional")
    
    return len(missing_required) == 0

async def test_firebase_connection():
    """Test Firebase connection"""
    print("\n🔥 Testing Firebase Connection...")
    
    try:
        from config.firebase_config import firebase_config
        
        result = firebase_config.initialize_firebase()
        if result:
            print("  ✅ Firebase initialization successful")
            
            # Test connection
            connection_test = firebase_config.test_connection()
            if connection_test:
                print("  ✅ Firebase connection test successful")
                return True
            else:
                print("  ❌ Firebase connection test failed")
                return False
        else:
            print("  ❌ Firebase initialization failed")
            return False
            
    except Exception as e:
        print(f"  ❌ Firebase test failed: {str(e)}")
        return False

async def test_gemini_ai():
    """Test Gemini AI connection"""
    print("\n🤖 Testing Gemini AI Connection...")
    
    try:
        from services.gemini_service import gemini_service
        
        if gemini_service.is_available():
            print("  ✅ Gemini AI initialization successful")
            
            # Test a simple query
            test_response = await gemini_service.generate_response("Hello, can you help me with banking?")
            if test_response and "AI service not available" not in test_response:
                print("  ✅ Gemini AI response test successful")
                print(f"  📝 Sample response: {test_response[:100]}...")
                return True
            else:
                print("  ❌ Gemini AI response test failed")
                return False
        else:
            print("  ❌ Gemini AI not available")
            return False
            
    except Exception as e:
        print(f"  ❌ Gemini AI test failed: {str(e)}")
        return False

async def test_agents():
    """Test agent initialization"""
    print("\n🤵 Testing Agent Initialization...")
    
    try:
        # Import agents
        from agents.multi_agent_system import MultiAgentSystem
        from config.firebase_config import firebase_config
        
        # Initialize Firebase first
        if not firebase_config.initialize_firebase():
            print("  ❌ Cannot test agents: Firebase not available")
            return False
        
        # Initialize agent system
        agent_system = MultiAgentSystem(firebase_config.get_firestore_client())
        # Note: MultiAgentSystem initializes agents in __init__, no separate initialize() method needed
        
        agents = agent_system.get_available_agents()
        print(f"  ✅ Successfully initialized {len(agents)} agents:")
        for agent_name in agents:
            print(f"    - {agent_name}")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Agent initialization failed: {str(e)}")
        return False

async def main():
    """Run all configuration tests"""
    print("🔧 Samsung Prism Multi-Agent System Configuration Test")
    print("=" * 60)
    
    # Load environment variables from .env file
    try:
        from dotenv import load_dotenv
        load_dotenv()
        print("✅ Loaded environment variables from .env file")
    except ImportError:
        print("⚠️  python-dotenv not installed, loading from system environment only")
    except Exception as e:
        print(f"⚠️  Could not load .env file: {str(e)}")
    
    # Run tests
    tests = [
        ("Environment Variables", test_environment_variables()),
        ("Firebase Connection", test_firebase_connection()),
        ("Gemini AI", test_gemini_ai()),
        ("Agent System", test_agents())
    ]
    
    results = []
    for test_name, test_coro in tests:
        try:
            result = await test_coro
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test crashed: {str(e)}")
            results.append((test_name, False))
    
    # Summary
    print("\n📊 Test Summary")
    print("=" * 60)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status:8} {test_name}")
        if result:
            passed += 1
    
    print(f"\nResults: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Your configuration is ready.")
        print("🚀 You can now run: python main.py")
    else:
        print("\n❌ Some tests failed. Please check the configuration.")
        print("📖 See SETUP_GUIDE.md for detailed instructions.")
    
    return passed == total

if __name__ == "__main__":
    asyncio.run(main())

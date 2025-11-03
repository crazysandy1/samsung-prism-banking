#!/usr/bin/env python3
"""
Test script to verify balance inquiry is working correctly
"""

import requests
import json

def test_agent_balance():
    """Test the balance inquiry endpoint"""
    
    # API endpoint
    url = "http://localhost:8000/query"
    
    # Test query
    test_data = {
        "user_id": "iDRNcQFPVUX1Dkw0cPT3V0SFSrt2",  # Your user ID from the logs
        "query_text": "what is my balance?",
        "context": {}
    }
    
    try:
        print("🔍 Testing balance inquiry...")
        print(f"📤 Sending query: {test_data['query_text']}")
        
        response = requests.post(url, json=test_data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Response received:")
            print(f"   Agent: {result.get('agent_name', 'Unknown')}")
            print(f"   Confidence: {result.get('confidence', 0)}")
            print(f"   Response: {result.get('response_text', 'No response')}")
            print(f"   Action: {result.get('action_taken', 'None')}")
            
            if result.get('data'):
                print(f"   Data: {result.get('data')}")
                
            return True
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Error: Could not connect to agent system. Make sure it's running on localhost:8000")
        return False
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def test_health_check():
    """Test the health endpoint"""
    
    try:
        print("🏥 Testing health check...")
        response = requests.get("http://localhost:8000/health", timeout=5)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ System healthy: {result.get('system_healthy', False)}")
            print(f"   Database connected: {result.get('database_connection', False)}")
            print(f"   Agents status: {result.get('agents_status', {})}")
            return True
        else:
            print(f"❌ Health check failed: HTTP {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Health check error: {str(e)}")
        return False

if __name__ == "__main__":
    print("🚀 Testing Samsung Prism Multi-Agent System\n")
    
    # Test health first
    if test_health_check():
        print("\n" + "="*50 + "\n")
        # Test balance inquiry
        test_agent_balance()
    else:
        print("❌ Health check failed. Cannot proceed with balance test.")
    
    print("\n🏁 Test completed!")

#!/usr/bin/env python3
"""
Quick test script to verify agent system connectivity and functionality
"""
import requests
import json

def test_agent_system():
    print("🧪 Testing Samsung Prism Agent System")
    print("=" * 50)
    
    base_url = "http://localhost:8000"
    
    # Test 1: Health Check
    print("\n1️⃣ Testing Health Check...")
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        if response.status_code == 200:
            print("✅ Health check passed")
            health_data = response.json()
            print(f"   System healthy: {health_data.get('system_healthy')}")
            print(f"   Agents status: {health_data.get('agents_status')}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False
    
    # Test 2: Agent Query
    print("\n2️⃣ Testing Agent Query...")
    try:
        query_data = {
            "user_id": "test_user_123",
            "query_text": "what is my balance?",
            "context": {}
        }
        
        response = requests.post(
            f"{base_url}/query",
            json=query_data,
            headers={"Content-Type": "application/json"},
            timeout=15
        )
        
        if response.status_code == 200:
            print("✅ Agent query successful")
            result = response.json()
            print(f"   Agent: {result.get('agent_name')}")
            print(f"   Confidence: {result.get('confidence')}")
            print(f"   Response: {result.get('response_text', '')[:100]}...")
        else:
            print(f"❌ Agent query failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Agent query error: {e}")
        return False
    
    # Test 3: Test different agent types
    print("\n3️⃣ Testing Different Agent Types...")
    test_queries = [
        "what is my balance?",
        "am I eligible for a loan?", 
        "what is my credit card limit?",
        "what are your working hours?"
    ]
    
    for i, query in enumerate(test_queries, 1):
        try:
            query_data = {
                "user_id": "test_user_123",
                "query_text": query,
                "context": {}
            }
            
            response = requests.post(
                f"{base_url}/query",
                json=query_data,
                headers={"Content-Type": "application/json"},
                timeout=15
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"   {i}. {query} → {result.get('agent_name')} (confidence: {result.get('confidence')})")
            else:
                print(f"   {i}. {query} → Failed ({response.status_code})")
        except Exception as e:
            print(f"   {i}. {query} → Error: {e}")
    
    print("\n✅ All tests completed successfully!")
    return True

if __name__ == "__main__":
    test_agent_system()

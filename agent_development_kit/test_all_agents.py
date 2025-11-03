#!/usr/bin/env python3
"""
Comprehensive test script for all Samsung Prism agents
"""

import requests
import json
import time

def test_agent_query(query_text, expected_agent=None):
    """Test a specific query against the agent system"""
    
    url = "http://localhost:8000/query"
    
    test_data = {
        "user_id": "iDRNcQFPVUX1Dkw0cPT3V0SFSrt2",
        "query_text": query_text,
        "context": {}
    }
    
    try:
        print(f"📤 Testing: '{query_text}'")
        
        response = requests.post(url, json=test_data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            agent_name = result.get('agent_name', 'Unknown')
            confidence = result.get('confidence', 0)
            response_text = result.get('response_text', 'No response')
            action = result.get('action_taken', 'None')
            
            print(f"✅ Agent: {agent_name} (Confidence: {confidence:.2f})")
            print(f"📝 Action: {action}")
            print(f"💬 Response: {response_text[:150]}{'...' if len(response_text) > 150 else ''}")
            
            if expected_agent and agent_name != expected_agent:
                print(f"⚠️  Expected {expected_agent}, got {agent_name}")
            
            print("=" * 80)
            return True
            
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def run_comprehensive_test():
    """Run comprehensive tests for all agents"""
    
    print("🚀 Samsung Prism Multi-Agent System - Comprehensive Test\n")
    
    # Test cases for each agent
    test_cases = [
        # AccountAgent tests
        ("what is my balance?", "AccountAgent"),
        ("show me my recent transactions", "AccountAgent"),
        ("how much money do I have?", "AccountAgent"),
        ("transaction history", "AccountAgent"),
        
        # LoanAgent tests
        ("am I eligible for a personal loan?", "LoanAgent"),
        ("what are the interest rates for home loan?", "LoanAgent"),
        ("can I get a car loan?", "LoanAgent"),
        ("tell me about education loan", "LoanAgent"),
        ("calculate EMI for 500000", "LoanAgent"),
        
        # CardAgent tests
        ("what is my credit card limit?", "CardAgent"),
        ("how to activate my debit card?", "CardAgent"),
        ("block my credit card", "CardAgent"),
        ("card status", "CardAgent"),
        ("change my card PIN", "CardAgent"),
        
        # SupportAgent tests
        ("what is your customer care number?", "SupportAgent"),
        ("how to download mobile app?", "SupportAgent"),
        ("bank working hours", "SupportAgent"),
        ("where is the nearest branch?", "SupportAgent"),
        ("how to register for internet banking?", "SupportAgent"),
        ("I have a complaint", "SupportAgent"),
        
        # General queries (should route to appropriate agent)
        ("help me with banking", None),
        ("I need assistance", None),
        ("what services do you offer?", None),
    ]
    
    success_count = 0
    total_tests = len(test_cases)
    
    for i, (query, expected_agent) in enumerate(test_cases, 1):
        print(f"Test {i}/{total_tests}")
        if test_agent_query(query, expected_agent):
            success_count += 1
        time.sleep(1)  # Brief pause between tests
    
    print(f"\n📊 Test Summary:")
    print(f"Total Tests: {total_tests}")
    print(f"Successful: {success_count}")
    print(f"Failed: {total_tests - success_count}")
    print(f"Success Rate: {(success_count/total_tests)*100:.1f}%")
    
    return success_count == total_tests

def test_health_check():
    """Test system health"""
    try:
        response = requests.get("http://localhost:8000/health", timeout=5)
        if response.status_code == 200:
            result = response.json()
            print("🏥 System Health Check:")
            print(f"   System Healthy: {result.get('system_healthy', False)}")
            print(f"   Database Connected: {result.get('database_connection', False)}")
            
            agents_status = result.get('agents_status', {})
            print(f"   Agents Status:")
            for agent_name, status in agents_status.items():
                health = "✅" if status.get('healthy', False) else "❌"
                print(f"     {health} {status.get('agent_name', agent_name)}")
            
            return result.get('system_healthy', False)
        else:
            print(f"❌ Health check failed: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {str(e)}")
        return False

if __name__ == "__main__":
    print("🏦 Samsung Prism Multi-Agent Banking System")
    print("=" * 80)
    
    # Check system health first
    if test_health_check():
        print("\n" + "=" * 80)
        # Run comprehensive tests
        success = run_comprehensive_test()
        
        if success:
            print("\n🎉 All tests passed! System is working correctly.")
        else:
            print("\n⚠️  Some tests failed. Check the output above for details.")
    else:
        print("\n❌ System health check failed. Cannot proceed with tests.")
        print("Make sure the agent system is running on localhost:8000")

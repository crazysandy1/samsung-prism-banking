#!/usr/bin/env python3
# PythonAnywhere Deployment Test Script
# Run this to verify your keystroke authentication backend is working

import os
import sys
import requests
import json
from datetime import datetime

def test_health_endpoint(base_url):
    """Test the health endpoint"""
    try:
        response = requests.get(f"{base_url}/health")
        if response.status_code == 200:
            data = response.json()
            print("✅ Health check passed")
            print(f"   Status: {data.get('status')}")
            print(f"   Service: {data.get('service')}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_user_info_endpoint(base_url):
    """Test the user info endpoint"""
    try:
        response = requests.get(f"{base_url}/user/demo_user/info")
        if response.status_code == 200:
            data = response.json()
            print("✅ User info endpoint working")
            print(f"   User ID: {data.get('user_id')}")
            print(f"   Samples: {data.get('samples_count', 0)}")
            return True
        elif response.status_code == 404:
            print("✅ User info endpoint working (user not found, expected)")
            return True
        else:
            print(f"❌ User info failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ User info error: {e}")
        return False

def test_train_endpoint(base_url):
    """Test the train endpoint with sample data"""
    try:
        # Sample keystroke data
        sample_data = {
            "user_id": "test_user",
            "keystroke_data": [
                {"key": "t", "event": "down", "timestamp": 100},
                {"key": "t", "event": "up", "timestamp": 250},
                {"key": "e", "event": "down", "timestamp": 300},
                {"key": "e", "event": "up", "timestamp": 450},
                {"key": "s", "event": "down", "timestamp": 500},
                {"key": "s", "event": "up", "timestamp": 650},
                {"key": "t", "event": "down", "timestamp": 700},
                {"key": "t", "event": "up", "timestamp": 850}
            ]
        }

        response = requests.post(
            f"{base_url}/train",
            json=sample_data,
            headers={'Content-Type': 'application/json'}
        )

        if response.status_code == 200:
            data = response.json()
            print("✅ Training endpoint working")
            print(f"   Status: {data.get('status')}")
            print(f"   Samples: {data.get('samples_count', 0)}")
            print(f"   Model trained: {data.get('model_trained', False)}")
            return True
        else:
            print(f"❌ Training failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Training error: {e}")
        return False

def main():
    print("=" * 60)
    print("PythonAnywhere Keystroke Auth Deployment Test")
    print("=" * 60)
    print(f"Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    # Get base URL from environment or user input
    base_url = os.environ.get('PYTHONANYWHERE_URL')

    if not base_url:
        # Try to detect PythonAnywhere domain
        domain = os.environ.get('PYTHONANYWHERE_DOMAIN')
        if domain:
            base_url = f"https://{domain}"
        else:
            # Ask user for URL
            base_url = input("Enter your PythonAnywhere app URL (e.g., https://yourusername.pythonanywhere.com): ").strip()

    if not base_url:
        print("❌ No URL provided. Set PYTHONANYWHERE_URL environment variable or enter URL manually.")
        sys.exit(1)

    print(f"Testing deployment at: {base_url}")
    print()

    # Run tests
    tests_passed = 0
    total_tests = 3

    if test_health_endpoint(base_url):
        tests_passed += 1

    if test_user_info_endpoint(base_url):
        tests_passed += 1

    if test_train_endpoint(base_url):
        tests_passed += 1

    print()
    print("=" * 60)
    print(f"Test Results: {tests_passed}/{total_tests} tests passed")

    if tests_passed == total_tests:
        print("🎉 All tests passed! Your deployment is working correctly.")
        print()
        print("Next steps:")
        print("1. Update your Flutter app to use this URL")
        print("2. Test with real keystroke data")
        print("3. Monitor usage in PythonAnywhere dashboard")
    else:
        print("⚠️  Some tests failed. Check the errors above.")
        print("   Make sure your web app is properly configured in PythonAnywhere.")

    print("=" * 60)

if __name__ == "__main__":
    main()

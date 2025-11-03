"""
Test Script for Keystroke Dynamics Authentication Backend

This script demonstrates how to use the Flask API endpoints for training 
and authentication with sample keystroke data.

Usage: python test_api.py
(Make sure the Flask server is running first)
"""

import requests
import json
import time
import random

# Configuration
BASE_URL = "http://localhost:5000"
TEST_USER_ID = "test_user_001"

# Sample keystroke data simulating typing "password"
def generate_sample_keystroke_data(base_timing=100, variation=50):
    """
    Generate realistic keystroke timing data for the word "password"
    
    Args:
        base_timing (int): Base timing between events in milliseconds
        variation (int): Random variation to add to timings
    
    Returns:
        list: Keystroke events with realistic timing patterns
    """
    word = "password"
    keystroke_data = []
    current_time = random.randint(1000, 2000)  # Start time
    
    for char in word:
        # Key down event
        keystroke_data.append({
            "key": char,
            "event": "down",
            "timestamp": current_time
        })
        
        # Key up event (hold time: 80-200ms)
        hold_time = random.randint(80, 200)
        keystroke_data.append({
            "key": char,
            "event": "up", 
            "timestamp": current_time + hold_time
        })
        
        # Time to next key (flight time: 50-300ms)
        flight_time = random.randint(50, 300)
        current_time += hold_time + flight_time
    
    return keystroke_data


def test_health_check():
    """Test the health check endpoint."""
    print("🔍 Testing health check endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check passed: {data['status']}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Make sure Flask app is running!")
        return False


def test_user_info(user_id):
    """Test getting user information."""
    print(f"🔍 Getting info for user: {user_id}")
    
    try:
        response = requests.get(f"{BASE_URL}/user/{user_id}/info")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ User info retrieved:")
            print(f"   Training samples: {data['training_samples']}")
            print(f"   Has model: {data['has_trained_model']}")
            print(f"   Required samples: {data['min_samples_required']}")
            return data
        else:
            print(f"❌ Failed to get user info: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ Error getting user info: {e}")
        return None


def test_training(user_id, num_samples=6):
    """Test the training endpoint with multiple samples."""
    print(f"🔍 Training user model with {num_samples} samples...")
    
    training_results = []
    
    for i in range(num_samples):
        print(f"   Sending training sample {i+1}/{num_samples}...")
        
        # Generate sample keystroke data
        keystroke_data = generate_sample_keystroke_data()
        
        payload = {
            "user_id": user_id,
            "keystroke_data": keystroke_data
        }
        
        try:
            response = requests.post(
                f"{BASE_URL}/train",
                headers={"Content-Type": "application/json"},
                data=json.dumps(payload)
            )
            
            if response.status_code == 200:
                data = response.json()
                training_results.append(data)
                
                print(f"   ✅ Sample {i+1} processed:")
                print(f"      Samples count: {data['samples_count']}")
                print(f"      Model trained: {data.get('model_trained', False)}")
                
                if data.get('model_trained', False):
                    print("   🎉 Model training completed!")
                    
            else:
                print(f"   ❌ Training failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"   ❌ Error during training: {e}")
        
        # Small delay between requests
        time.sleep(0.5)
    
    return training_results


def test_authentication(user_id, num_tests=3):
    """Test the authentication endpoint."""
    print(f"🔍 Testing authentication for user: {user_id}")
    
    auth_results = []
    
    for i in range(num_tests):
        print(f"   Authentication test {i+1}/{num_tests}...")
        
        # Generate keystroke data (should be recognized as genuine user)
        keystroke_data = generate_sample_keystroke_data()
        
        payload = {
            "user_id": user_id,
            "keystroke_data": keystroke_data
        }
        
        try:
            response = requests.post(
                f"{BASE_URL}/predict",
                headers={"Content-Type": "application/json"},
                data=json.dumps(payload)
            )
            
            if response.status_code == 200:
                data = response.json()
                auth_results.append(data)
                
                if data['authenticated']:
                    print(f"   ✅ Authentication successful!")
                    print(f"      Confidence score: {data.get('confidence_score', 'N/A')}")
                else:
                    print(f"   ❌ Authentication failed:")
                    print(f"      Reason: {data.get('reason', 'Unknown')}")
                    print(f"      Confidence score: {data.get('confidence_score', 'N/A')}")
                    
            else:
                print(f"   ❌ Authentication request failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"   ❌ Error during authentication: {e}")
        
        time.sleep(0.5)
    
    return auth_results


def test_imposter_detection(user_id):
    """Test authentication with different typing patterns (imposter simulation)."""
    print(f"🔍 Testing imposter detection for user: {user_id}")
    
    # Generate keystroke data with very different timing patterns
    print("   Generating imposter keystroke pattern...")
    
    # Create abnormal timing patterns
    word = "password"
    keystroke_data = []
    current_time = 1000
    
    for char in word:
        # Abnormally long hold times and flight times
        keystroke_data.append({
            "key": char,
            "event": "down",
            "timestamp": current_time
        })
        
        # Very long hold time (500-800ms vs normal 80-200ms)
        hold_time = random.randint(500, 800)
        keystroke_data.append({
            "key": char,
            "event": "up",
            "timestamp": current_time + hold_time
        })
        
        # Very long flight time (800-1200ms vs normal 50-300ms)
        flight_time = random.randint(800, 1200)
        current_time += hold_time + flight_time
    
    payload = {
        "user_id": user_id,
        "keystroke_data": keystroke_data
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/predict",
            headers={"Content-Type": "application/json"},
            data=json.dumps(payload)
        )
        
        if response.status_code == 200:
            data = response.json()
            
            if not data['authenticated']:
                print(f"   ✅ Imposter correctly detected!")
                print(f"      Reason: {data.get('reason', 'Unknown')}")
                print(f"      Confidence score: {data.get('confidence_score', 'N/A')}")
            else:
                print(f"   ⚠️  Imposter not detected (false positive)")
                print(f"      Confidence score: {data.get('confidence_score', 'N/A')}")
                
        else:
            print(f"   ❌ Imposter test failed: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"   ❌ Error during imposter test: {e}")


def main():
    """Run the complete test suite."""
    print("🚀 Starting Keystroke Dynamics Authentication API Tests")
    print("=" * 60)
    
    # Test 1: Health check
    if not test_health_check():
        print("❌ Server not available. Exiting tests.")
        return
    
    print()
    
    # Test 2: Initial user info (should show no data)
    test_user_info(TEST_USER_ID)
    print()
    
    # Test 3: Training with multiple samples
    training_results = test_training(TEST_USER_ID, num_samples=6)
    print()
    
    # Test 4: User info after training
    test_user_info(TEST_USER_ID)
    print()
    
    # Test 5: Authentication tests
    auth_results = test_authentication(TEST_USER_ID, num_tests=3)
    print()
    
    # Test 6: Imposter detection
    test_imposter_detection(TEST_USER_ID)
    print()
    
    # Summary
    print("📊 Test Summary:")
    print("=" * 60)
    
    if training_results:
        final_training = training_results[-1]
        print(f"Training samples collected: {final_training.get('samples_count', 0)}")
        print(f"Model trained: {final_training.get('model_trained', False)}")
    
    if auth_results:
        successful_auths = sum(1 for result in auth_results if result.get('authenticated', False))
        print(f"Authentication tests: {len(auth_results)}")
        print(f"Successful authentications: {successful_auths}")
    
    print()
    print("✅ All tests completed!")
    print("🔗 You can now integrate this API with your Flutter mobile app.")


if __name__ == "__main__":
    main()

"""
Flask Backend Application for Keystroke Dynamics Authentication

This application serves as a backend for a keystroke dynamics authentication system.
It provides REST API endpoints for training machine learning models on user typing patterns
and predicting whether new typing samples belong to genuine users or imposters.

Based on the reference repository:
https://github.com/nikhilagr/User-Authentication-using-keystroke-dynamics

Author: Generated for Samsung Prism Project
Date: August 27, 2025
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from sklearn.ensemble import IsolationForest
import numpy as np
import joblib
import os
import json
import logging
from datetime import datetime
from config import get_config, FeatureExtractionConfig, ModelConfig, APIConfig, DEFAULT_MODEL_METADATA

# Initialize Flask application
app = Flask(__name__)

# Load configuration
config = get_config()
app.config.from_object(config)

# Configure CORS if enabled
if config.ENABLE_CORS:
    # Check if we're on PythonAnywhere
    pythonanywhere_domain = os.environ.get('PYTHONANYWHERE_DOMAIN')
    
    if pythonanywhere_domain:
        # PythonAnywhere production CORS
        CORS(app, resources={
            r"/*": {
                "origins": [
                    f"https://{pythonanywhere_domain}",
                    "http://localhost:*",
                    "http://127.0.0.1:*",
                    "http://10.0.2.2:*"
                ],
                "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
                "allow_headers": ["Content-Type", "Authorization", "Accept"],
                "supports_credentials": False
            }
        })
    else:
        # Development CORS
        CORS(app, resources={
            r"/*": {
                "origins": ["http://localhost:*", "http://127.0.0.1:*", "http://10.0.2.2:*"],
                "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
                "allow_headers": ["Content-Type", "Authorization", "Accept"],
                "supports_credentials": True
            }
        })

# Configure logging
logging.basicConfig(
    level=getattr(logging, config.LOG_LEVEL),
    format=config.LOG_FORMAT
)
logger = logging.getLogger(__name__)

# Create model directory if it doesn't exist
if not os.path.exists(config.MODEL_DIR):
    os.makedirs(config.MODEL_DIR)
    logger.info(f"Created directory: {config.MODEL_DIR}")

# Global model cache for better performance
model_cache = {} if config.MODEL_CACHE_ENABLED else None


def extract_features(keystroke_data):
    """
    Extract meaningful features from raw keystroke data.
    
    This function processes a sequence of keystroke events and calculates three types of timing features:
    1. Hold Time (Dwell Time): Time between keydown and keyup for the same key
    2. Keydown-Keydown Time: Time between consecutive keydown events  
    3. Keyup-Keydown Time (Flight Time): Time between keyup and next keydown
    
    Args:
        keystroke_data (list): List of dictionaries with format:
                              [{'key': 'a', 'event': 'down', 'timestamp': 123}, ...]
    
    Returns:
        list: Feature vector containing calculated timing features in seconds
        
    Reference:
        Based on KeyDataStore.java process() method from the reference repository
    """
    if len(keystroke_data) < 2:
        logger.warning(f"Need at least 2 keystroke events, got {len(keystroke_data)}")
        return []
    
    if len(keystroke_data) > config.MAX_KEYSTROKE_EVENTS:
        logger.warning(f"Too many keystroke events ({len(keystroke_data)}), truncating to {config.MAX_KEYSTROKE_EVENTS}")
        keystroke_data = keystroke_data[:config.MAX_KEYSTROKE_EVENTS]
    
    # Group events by key to match press/release pairs
    key_events = {}
    event_sequence = []
    
    # First pass: organize events and create sequence
    for event in keystroke_data:
        key = event['key']
        event_type = event['event']
        timestamp = event['timestamp']
        
        if key not in key_events:
            key_events[key] = {'down': None, 'up': None}
            
        if event_type == 'down':
            key_events[key]['down'] = timestamp
        elif event_type == 'up':
            key_events[key]['up'] = timestamp
            
        event_sequence.append({
            'key': key,
            'event': event_type,
            'timestamp': timestamp
        })
    
    features = []
    
    # Process consecutive key pairs to extract features
    # Following the logic from KeyDataStore.java
    i = 0
    while i < len(event_sequence) - 1:
        current_event = event_sequence[i]
        
        # Find the next keydown event to form a pair
        next_keydown_idx = i + 1
        while (next_keydown_idx < len(event_sequence) and 
               event_sequence[next_keydown_idx]['event'] != 'down'):
            next_keydown_idx += 1
            
        if next_keydown_idx >= len(event_sequence):
            break
            
        next_event = event_sequence[next_keydown_idx]
        
        # Calculate features for this key pair
        current_key = current_event['key']
        
        # 1. Hold Time: Time between keydown and keyup for current key
        if (key_events[current_key]['down'] is not None and 
            key_events[current_key]['up'] is not None):
            hold_time = (key_events[current_key]['up'] - key_events[current_key]['down']) / FeatureExtractionConfig.FEATURE_SCALE_FACTOR
            
            # Apply feature validation
            if 0 < hold_time <= FeatureExtractionConfig.MAX_HOLD_TIME:
                features.append(hold_time)
            else:
                logger.warning(f"Invalid hold time: {hold_time}s, skipping")
        
        # 2. Keydown-Keydown Time: Time between consecutive keydown events
        if current_event['event'] == 'down' and next_event['event'] == 'down':
            dd_time = (next_event['timestamp'] - current_event['timestamp']) / FeatureExtractionConfig.FEATURE_SCALE_FACTOR
            if dd_time > FeatureExtractionConfig.MIN_TIMING:
                features.append(dd_time)
        
        # 3. Keyup-Keydown Time: Time between keyup and next keydown
        # Find the keyup event for current key
        current_keyup_time = key_events[current_key]['up']
        if current_keyup_time is not None:
            ud_time = (next_event['timestamp'] - current_keyup_time) / FeatureExtractionConfig.FEATURE_SCALE_FACTOR
            if 0 < ud_time <= FeatureExtractionConfig.MAX_FLIGHT_TIME:
                features.append(ud_time)
        
        i = next_keydown_idx
    
    # Add hold time for the last key
    if len(event_sequence) > 0:
        last_key = event_sequence[-1]['key']
        if (key_events[last_key]['down'] is not None and 
            key_events[last_key]['up'] is not None):
            last_hold_time = (key_events[last_key]['up'] - key_events[last_key]['down']) / FeatureExtractionConfig.FEATURE_SCALE_FACTOR
            if 0 < last_hold_time <= FeatureExtractionConfig.MAX_HOLD_TIME:
                features.append(last_hold_time)
    
    logger.info(f"Extracted {len(features)} features from {len(keystroke_data)} keystroke events")
    return features


def load_user_features(user_id):
    """
    Load previously saved feature samples for a user.
    
    Args:
        user_id (str): Unique identifier for the user
        
    Returns:
        list: List of feature vectors, empty list if no data exists
    """
    features_file = os.path.join(config.MODEL_DIR, f"{user_id}_features.npy")
    if os.path.exists(features_file):
        try:
            features = np.load(features_file, allow_pickle=True).tolist()
            logger.info(f"Loaded {len(features)} existing feature samples for user {user_id}")
            return features
        except Exception as e:
            logger.error(f"Error loading features for user {user_id}: {e}")
            return []
    return []


def save_user_features(user_id, features):
    """
    Save feature samples for a user.
    
    Args:
        user_id (str): Unique identifier for the user
        features (list): List of feature vectors to save
    """
    features_file = os.path.join(config.MODEL_DIR, f"{user_id}_features.npy")
    try:
        np.save(features_file, features)
        logger.info(f"Saved {len(features)} feature samples for user {user_id}")
    except Exception as e:
        logger.error(f"Error saving features for user {user_id}: {e}")


def pad_features(features_list):
    """
    Pad feature vectors to have the same length by adding zeros.
    This ensures consistent input dimensions for the ML model.
    
    Args:
        features_list (list): List of feature vectors with potentially different lengths
        
    Returns:
        numpy.ndarray: 2D array with padded features of consistent length
    """
    if not features_list:
        return np.array([])
        
    max_length = max(len(features) for features in features_list)
    padded_features = []
    
    for features in features_list:
        padded = features + [0.0] * (max_length - len(features))
        padded_features.append(padded)
    
    return np.array(padded_features)


def load_user_model(user_id):
    """
    Load a trained model for a specific user.
    
    Args:
        user_id (str): Unique identifier for the user
        
    Returns:
        tuple: (model, max_feature_length) or (None, None) if model doesn't exist
    """
    # Check cache first
    if model_cache and user_id in model_cache:
        logger.info(f"Loading model for user {user_id} from cache")
        return model_cache[user_id]
    
    model_file = os.path.join(config.MODEL_DIR, f"{user_id}.joblib")
    metadata_file = os.path.join(config.MODEL_DIR, f"{user_id}_metadata.json")
    
    if os.path.exists(model_file) and os.path.exists(metadata_file):
        try:
            model = joblib.load(model_file)
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
            max_feature_length = metadata.get('max_feature_length', 0)
            
            result = (model, max_feature_length)
            
            # Cache the model for future use
            if model_cache:
                model_cache[user_id] = result
                
            logger.info(f"Loaded model for user {user_id} with feature length {max_feature_length}")
            return result
        except Exception as e:
            logger.error(f"Error loading model for user {user_id}: {e}")
            return None, None
    return None, None


def save_user_model(user_id, model, max_feature_length):
    """
    Save a trained model and its metadata for a user.
    
    Args:
        user_id (str): Unique identifier for the user
        model: Trained scikit-learn model
        max_feature_length (int): Maximum feature vector length used in training
    """
    model_file = os.path.join(config.MODEL_DIR, f"{user_id}.joblib")
    metadata_file = os.path.join(config.MODEL_DIR, f"{user_id}_metadata.json")
    
    try:
        joblib.dump(model, model_file)
        
        metadata = DEFAULT_MODEL_METADATA.copy()
        metadata.update({
            'max_feature_length': max_feature_length,
            'created_at': datetime.now().isoformat(),
            'user_id': user_id
        })
        
        with open(metadata_file, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        # Update cache
        if model_cache:
            model_cache[user_id] = (model, max_feature_length)
            
        logger.info(f"Saved model for user {user_id} with feature length {max_feature_length}")
    except Exception as e:
        logger.error(f"Error saving model for user {user_id}: {e}")


@app.route('/train', methods=['POST'])
def train_endpoint():
    """
    API endpoint for training a user's keystroke dynamics model.
    
    Expected JSON format:
    {
        "user_id": "unique_user_identifier",
        "keystroke_data": [
            {"key": "p", "event": "down", "timestamp": 100},
            {"key": "p", "event": "up", "timestamp": 250},
            ...
        ]
    }
    
    Returns:
        JSON response indicating success/failure
    """
    try:
        # Validate request data
        if not request.is_json:
            return jsonify({"error": "Request must be JSON"}), 400
            
        data = request.get_json()
        
        if 'user_id' not in data or 'keystroke_data' not in data:
            return jsonify({"error": "Missing required fields: user_id, keystroke_data"}), 400
            
        user_id = data['user_id']
        keystroke_data = data['keystroke_data']
        
        if not isinstance(keystroke_data, list) or len(keystroke_data) == 0:
            return jsonify({"error": "keystroke_data must be a non-empty list"}), 400
        
        print(f"Training request for user {user_id} with {len(keystroke_data)} keystroke events")
        
        # Extract features from the current sample
        current_features = extract_features(keystroke_data)
        
        if not current_features:
            return jsonify({"error": "Unable to extract features from keystroke data"}), 400
        
        # Load existing features for this user
        existing_features = load_user_features(user_id)
        
        # Add the new feature vector to the existing ones
        existing_features.append(current_features)
        
        # Save the updated feature collection
        save_user_features(user_id, existing_features)
        
        # Check if we have enough samples to train a model
        if len(existing_features) >= config.MIN_SAMPLES_FOR_TRAINING:
            # Pad features to ensure consistent dimensions
            padded_features = pad_features(existing_features)
            
            if padded_features.size > 0:
                # Train IsolationForest model
                # Using contamination from config to automatically determine the proportion of outliers
                model = IsolationForest(
                    contamination=config.ISOLATION_FOREST_CONTAMINATION,
                    random_state=config.RANDOM_STATE,
                    n_estimators=ModelConfig.N_ESTIMATORS,
                    n_jobs=ModelConfig.N_JOBS
                )
                model.fit(padded_features)
                
                # Save the trained model with metadata
                max_feature_length = padded_features.shape[1] if len(padded_features.shape) > 1 else len(current_features)
                save_user_model(user_id, model, max_feature_length)
                
                logger.info(f"Successfully trained model for user {user_id} with {len(existing_features)} samples")
                return jsonify({
                    "status": APIConfig.TRAINING_SUCCESS,
                    "samples_count": len(existing_features),
                    "model_trained": True
                }), 200
            else:
                return jsonify({"error": "Failed to process features for training"}), 500
        else:
            logger.info(f"User {user_id} has {len(existing_features)} samples, need {config.MIN_SAMPLES_FOR_TRAINING} for training")
            return jsonify({
                "status": APIConfig.TRAINING_SUCCESS,
                "samples_count": len(existing_features),
                "model_trained": False,
                "message": f"Need {config.MIN_SAMPLES_FOR_TRAINING} samples to train model"
            }), 200
            
    except Exception as e:
        print(f"Error in train endpoint: {e}")
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@app.route('/predict', methods=['POST'])
def predict_endpoint():
    """
    API endpoint for predicting authentication based on keystroke dynamics.
    
    Expected JSON format: Same as /train endpoint
    
    Returns:
        JSON response with authentication result:
        - {"authenticated": true} for genuine user
        - {"authenticated": false, "reason": "..."} for imposter
        - {"error": "..."} for errors
    """
    try:
        # Validate request data
        if not request.is_json:
            return jsonify({"error": "Request must be JSON"}), 400
            
        data = request.get_json()
        
        if 'user_id' not in data or 'keystroke_data' not in data:
            return jsonify({"error": "Missing required fields: user_id, keystroke_data"}), 400
            
        user_id = data['user_id']
        keystroke_data = data['keystroke_data']
        
        if not isinstance(keystroke_data, list) or len(keystroke_data) == 0:
            return jsonify({"error": "keystroke_data must be a non-empty list"}), 400
        
        print(f"Prediction request for user {user_id} with {len(keystroke_data)} keystroke events")
        
        # Load the trained model for this user
        model, max_feature_length = load_user_model(user_id)
        
        if model is None:
            return jsonify({"error": APIConfig.USER_MODEL_NOT_FOUND}), 404
        
        # Extract features from the new keystroke data
        new_features = extract_features(keystroke_data)
        
        if not new_features:
            return jsonify({"error": APIConfig.FEATURE_EXTRACTION_FAILED}), 400
        
        # Pad the new features to match the model's expected input dimensions
        if len(new_features) < max_feature_length:
            new_features.extend([0.0] * (max_feature_length - len(new_features)))
        elif len(new_features) > max_feature_length:
            # Truncate if longer (though this shouldn't happen in normal circumstances)
            new_features = new_features[:max_feature_length]
        
        # Reshape for prediction (model expects 2D array)
        feature_vector = np.array(new_features).reshape(1, -1)
        
        # Make prediction
        # IsolationForest returns 1 for inliers (genuine user) and -1 for outliers (imposter)
        prediction = model.predict(feature_vector)[0]
        
        # Get anomaly score for additional information
        anomaly_score = model.decision_function(feature_vector)[0]
        
        print(f"Prediction for user {user_id}: {prediction}, anomaly_score: {anomaly_score}")
        
        if prediction == 1:
            # Genuine user (inlier)
            return jsonify({
                "authenticated": True,
                "confidence_score": float(anomaly_score),
                "user_id": user_id
            }), 200
        else:
            # Imposter (outlier/anomaly)
            return jsonify({
                "authenticated": False,
                "reason": "Typing pattern anomaly detected",
                "confidence_score": float(anomaly_score),
                "user_id": user_id
            }), 200
            
    except Exception as e:
        print(f"Error in predict endpoint: {e}")
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@app.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint to verify the API is running.
    """
    return jsonify({
        "status": "healthy",
        "service": "Keystroke Dynamics Authentication API",
        "timestamp": datetime.now().isoformat()
    }), 200


@app.route('/user/<user_id>/info', methods=['GET'])
def get_user_info(user_id):
    """
    Get information about a user's training data and model status.
    
    Args:
        user_id (str): User identifier in URL path
        
    Returns:
        JSON with user training information
    """
    try:
        # Check if user has training data
        existing_features = load_user_features(user_id)
        
        # Check if user has a trained model
        model, max_feature_length = load_user_model(user_id)
        has_model = model is not None
        
        return jsonify({
            "user_id": user_id,
            "training_samples": len(existing_features),
            "has_trained_model": has_model,
            "min_samples_required": config.MIN_SAMPLES_FOR_TRAINING,
            "max_feature_length": max_feature_length if has_model else None
        }), 200
        
    except Exception as e:
        print(f"Error getting user info for {user_id}: {e}")
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@app.route('/', methods=['OPTIONS'])
@app.route('/<path:path>', methods=['OPTIONS'])
def handle_options(path=None):
    """Handle CORS preflight requests"""
    return '', 200


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(405)
def method_not_allowed(error):
    """Handle 405 errors."""
    return jsonify({"error": "Method not allowed"}), 405


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    print("=" * 60)
    print("Keystroke Dynamics Authentication Backend")
    print("=" * 60)
    print(f"Model storage directory: {config.MODEL_DIR}")
    print(f"Minimum samples for training: {config.MIN_SAMPLES_FOR_TRAINING}")
    print("Available endpoints:")
    print("  POST /train    - Train user keystroke model")
    print("  POST /predict  - Authenticate user via keystroke")
    print("  GET  /health   - Health check")
    print("  GET  /user/<id>/info - Get user training info")
    print("=" * 60)
    
    # Run the Flask app
    # Using host='0.0.0.0' to make it accessible from mobile devices on the same network
    app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG)

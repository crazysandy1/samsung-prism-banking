"""
Configuration Module for Keystroke Dynamics Authentication Backend

This module contains all configurable parameters for the Flask application.
Modify these settings according to your deployment requirements.
"""

import os


class Config:
    """Base configuration class with default settings."""
    
    # Server Configuration
    HOST = os.environ.get('FLASK_HOST', '0.0.0.0')
    PORT = int(os.environ.get('FLASK_PORT', 5000))
    DEBUG = os.environ.get('FLASK_DEBUG', 'True').lower() == 'true'
    
    # Model Storage Configuration
    MODEL_DIR = os.environ.get('MODEL_DIR', 'user_models')
    
    # Machine Learning Configuration
    MIN_SAMPLES_FOR_TRAINING = int(os.environ.get('MIN_SAMPLES', 5))
    ISOLATION_FOREST_CONTAMINATION = float(os.environ.get('CONTAMINATION', 0.1))  # Expected proportion of outliers
    RANDOM_STATE = int(os.environ.get('RANDOM_STATE', 42))
    
    # Feature Extraction Configuration
    TIMESTAMP_UNIT = os.environ.get('TIMESTAMP_UNIT', 'milliseconds')  # 'milliseconds' or 'seconds'
    FEATURE_PADDING_VALUE = float(os.environ.get('FEATURE_PADDING_VALUE', 0.0))
    
    # API Configuration
    MAX_KEYSTROKE_EVENTS = int(os.environ.get('MAX_KEYSTROKE_EVENTS', 1000))  # Maximum events per request
    REQUEST_TIMEOUT = int(os.environ.get('REQUEST_TIMEOUT', 30))  # Seconds
    
    # Logging Configuration
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    # Security Configuration
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-key-change-in-production')
    ENABLE_CORS = os.environ.get('ENABLE_CORS', 'True').lower() == 'true'
    
    # Performance Configuration
    FEATURE_CACHE_ENABLED = os.environ.get('FEATURE_CACHE_ENABLED', 'True').lower() == 'true'
    MODEL_CACHE_ENABLED = os.environ.get('MODEL_CACHE_ENABLED', 'True').lower() == 'true'


class DevelopmentConfig(Config):
    """Development configuration with debug settings."""
    DEBUG = True
    LOG_LEVEL = 'DEBUG'


class ProductionConfig(Config):
    """Production configuration with security settings."""
    DEBUG = False
    LOG_LEVEL = 'WARNING'
    ENABLE_CORS = False  # Disable CORS in production unless specifically needed


class TestingConfig(Config):
    """Testing configuration for unit tests."""
    DEBUG = True
    TESTING = True
    MODEL_DIR = 'test_models'
    MIN_SAMPLES_FOR_TRAINING = 2  # Lower threshold for faster testing


# Configuration mapping
config_map = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}


def get_config():
    """Get configuration based on environment variable."""
    config_name = os.environ.get('FLASK_ENV', 'default')
    return config_map.get(config_name, DevelopmentConfig)


# Feature extraction constants
class FeatureExtractionConfig:
    """Configuration for feature extraction algorithms."""
    
    # Timing feature types
    HOLD_TIME = 'hold_time'
    KEYDOWN_KEYDOWN = 'keydown_keydown'
    KEYUP_KEYDOWN = 'keyup_keydown'
    
    # Feature normalization
    NORMALIZE_FEATURES = True
    FEATURE_SCALE_FACTOR = 1000.0  # Convert milliseconds to seconds
    
    # Outlier detection for features
    MAX_HOLD_TIME = 5.0  # Maximum reasonable hold time in seconds
    MAX_FLIGHT_TIME = 10.0  # Maximum reasonable flight time in seconds
    MIN_TIMING = 0.001  # Minimum timing value in seconds


# Model configuration
class ModelConfig:
    """Configuration for machine learning models."""
    
    # IsolationForest parameters
    N_ESTIMATORS = 100
    MAX_SAMPLES = 'auto'
    CONTAMINATION = 0.1
    RANDOM_STATE = 42
    BOOTSTRAP = False
    N_JOBS = -1  # Use all available CPU cores
    
    # Model validation
    ENABLE_MODEL_VALIDATION = True
    VALIDATION_SPLIT = 0.2
    MIN_ACCURACY_THRESHOLD = 0.7


# API Response codes and messages
class APIConfig:
    """Configuration for API responses and error messages."""
    
    # Success messages
    TRAINING_SUCCESS = "Training data received"
    AUTHENTICATION_SUCCESS = "Authentication successful"
    HEALTH_CHECK_SUCCESS = "Service is healthy"
    
    # Error messages
    INVALID_JSON = "Request must be valid JSON"
    MISSING_FIELDS = "Missing required fields"
    INVALID_KEYSTROKE_DATA = "Invalid keystroke data format"
    USER_MODEL_NOT_FOUND = "User model not found. Please train the model first."
    FEATURE_EXTRACTION_FAILED = "Unable to extract features from keystroke data"
    INSUFFICIENT_TRAINING_DATA = "Insufficient training data for model creation"
    MODEL_TRAINING_FAILED = "Failed to train the model"
    MODEL_PREDICTION_FAILED = "Failed to make prediction"
    INTERNAL_SERVER_ERROR = "Internal server error occurred"
    
    # Authentication reasons
    TYPING_PATTERN_ANOMALY = "Typing pattern anomaly detected"
    INSUFFICIENT_CONFIDENCE = "Insufficient confidence in authentication"


# Default user model metadata template
DEFAULT_MODEL_METADATA = {
    'model_type': 'IsolationForest',
    'version': '1.0',
    'feature_extraction_method': 'keystroke_dynamics',
    'training_parameters': {
        'n_estimators': ModelConfig.N_ESTIMATORS,
        'contamination': ModelConfig.CONTAMINATION,
        'random_state': ModelConfig.RANDOM_STATE
    }
}

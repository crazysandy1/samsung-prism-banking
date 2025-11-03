/// Configuration file for Keystroke Authentication System
/// 
/// This file contains all the configuration constants and settings
/// for the keystroke dynamics authentication system.

class KeystrokeConfig {
  // ===== SERVER CONFIGURATION =====
  
  /// Default server configurations
  static const String defaultServerIp = 'localhost';
  static const String defaultAndroidEmulatorIp = '10.0.2.2'; // Android emulator special IP
  static const int defaultPort = 5000;
  static const bool defaultUseHttps = false;
  
  /// Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration requestTimeout = Duration(seconds: 15);
  
  // ===== TRAINING CONFIGURATION =====
  
  /// Number of training samples required
  static const int requiredTrainingSamples = 5;
  
  /// Minimum password length for training
  static const int minPasswordLength = 4;
  
  /// Maximum password length for training
  static const int maxPasswordLength = 50;
  
  // ===== AUTHENTICATION CONFIGURATION =====
  
  /// Authentication confidence threshold (0.0 to 1.0)
  /// Higher values = more strict authentication
  static const double authenticationThreshold = 0.7;
  
  /// Maximum authentication attempts before lockout
  static const int maxAuthenticationAttempts = 3;
  
  /// Lockout duration after failed attempts
  static const Duration lockoutDuration = Duration(minutes: 5);
  
  // ===== UI CONFIGURATION =====
  
  /// Messages for user feedback
  static const String trainingCompleteMessage = 
      'Model training completed successfully! Your keystroke pattern has been saved.';
  
  static const String sampleCollectedMessage = 
      'Sample collected. Please type the password again.';
  
  static const String allSamplesCollectedMessage = 
      'All training samples collected! Ready to train your model.';
  
  static const String authenticationSuccessMessage = 
      'Keystroke authentication successful!';
  
  static const String authenticationFailureMessage = 
      'Keystroke pattern does not match. Please try again.';
  
  // ===== FEATURE EXTRACTION CONFIGURATION =====
  
  /// Minimum number of keystroke events required
  static const int minKeystrokeEvents = 2;
  
  /// Maximum number of keystroke events to process
  static const int maxKeystrokeEvents = 100;
  
  // ===== SECURITY CONFIGURATION =====
  
  /// Enable/disable keystroke authentication
  static const bool isKeystrokeAuthEnabled = true;
  
  /// Enable fallback to password-only authentication
  static const bool allowPasswordFallback = true;
  
  /// Enable debug logging
  static const bool enableDebugLogging = true;
  
  // ===== STORAGE CONFIGURATION =====
  
  /// Preference keys for storing configuration
  static const String prefKeyServerIp = 'keystroke_server_ip';
  static const String prefKeyServerPort = 'keystroke_server_port';
  static const String prefKeyUseHttps = 'keystroke_use_https';
  static const String prefKeyIsConfigured = 'keystroke_is_configured';
  static const String prefKeyUserTrained = 'keystroke_user_trained';
  static const String prefKeyLastTrainingDate = 'keystroke_last_training_date';
  
  // ===== HELPER METHODS =====
  
  /// Get the appropriate server IP based on platform
  static String getServerIp() {
    // For Android emulator, use special IP mapping
    // In a real implementation, you might detect the platform here
    return defaultServerIp;
  }
  
  /// Get the full server URL
  static String getServerUrl({
    String? serverIp,
    int? port,
    bool? useHttps,
  }) {
    final ip = serverIp ?? getServerIp();
    final portNum = port ?? defaultPort;
    final secure = useHttps ?? defaultUseHttps;
    final protocol = secure ? 'https' : 'http';
    
    return '$protocol://$ip:$portNum';
  }
  
  /// Validate server URL format
  static bool isValidServerUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  
  /// Get training progress percentage
  static double getTrainingProgress(int samplesCollected) {
    return (samplesCollected / requiredTrainingSamples).clamp(0.0, 1.0);
  }
  
  /// Check if training is complete
  static bool isTrainingComplete(int samplesCollected) {
    return samplesCollected >= requiredTrainingSamples;
  }
  
  /// Get sample collection message
  static String getSampleMessage(int samplesCollected) {
    if (samplesCollected >= requiredTrainingSamples) {
      return allSamplesCollectedMessage;
    } else {
      return 'Sample $samplesCollected/$requiredTrainingSamples collected. $sampleCollectedMessage';
    }
  }
}

/// Platform-specific configurations
class PlatformKeystrokeConfig {
  /// Android-specific configurations
  static const Map<String, dynamic> android = {
    'server_ip': '10.0.2.2', // Android emulator special IP
    'connection_timeout': 15, // seconds
    'request_timeout': 20, // seconds
  };
  
  /// iOS-specific configurations
  static const Map<String, dynamic> ios = {
    'server_ip': 'localhost',
    'connection_timeout': 10, // seconds
    'request_timeout': 15, // seconds
  };
  
  /// Web-specific configurations
  static const Map<String, dynamic> web = {
    'server_ip': 'localhost',
    'connection_timeout': 8, // seconds
    'request_timeout': 12, // seconds
  };
}

/// Error messages for keystroke authentication
class KeystrokeErrorMessages {
  static const String serverConnectionFailed = 
      'Failed to connect to keystroke authentication server. Please check your network connection.';
  
  static const String trainingDataInsufficient = 
      'Insufficient training data. Please complete the training process.';
  
  static const String featureExtractionFailed = 
      'Failed to extract keystroke features. Please try typing again.';
  
  static const String modelTrainingFailed = 
      'Failed to train keystroke model. Please try the training process again.';
  
  static const String authenticationServerError = 
      'Authentication server error. Please try again later.';
  
  static const String invalidKeystrokeData = 
      'Invalid keystroke data format. Please try typing again.';
  
  static const String userNotTrained = 
      'User model not found. Please complete the training process first.';
  
  static const String networkError = 
      'Network error occurred. Please check your internet connection.';
}

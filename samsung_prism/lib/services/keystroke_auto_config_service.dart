import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/keystroke_config.dart';
import '../services/keystroke_auth_service.dart';

/// Service for automatically configuring keystroke authentication
/// based on the platform and environment.
class KeystrokeAutoConfigService {
  static KeystrokeAuthService? _service;
  static bool _isConfigured = false;
  
  /// Get the configured keystroke authentication service
  static KeystrokeAuthService get service {
    if (_service == null) {
      throw StateError('KeystrokeAutoConfigService not initialized. Call initialize() first.');
    }
    return _service!;
  }
  
  /// Check if the service is configured
  static bool get isConfigured => _isConfigured;
  
  /// Initialize the keystroke authentication service with automatic configuration
  static Future<bool> initialize() async {
    try {
      final config = _getAutoConfiguration();
      
      _service = KeystrokeAuthService.configure(
        serverIp: config['serverIp'],
        port: config['port'],
        useHttps: config['useHttps'],
      );
      
      // Test the connection
      final isConnected = await _service!.testConnection();
      _isConfigured = isConnected;
      
      if (_isConfigured) {
        if (kDebugMode) {
          print('✅ Keystroke authentication auto-configured successfully');
          print('   Server: ${config['serverIp']}:${config['port']}');
          print('   HTTPS: ${config['useHttps']}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Keystroke authentication server not available');
          print('   Attempted: ${config['serverIp']}:${config['port']}');
        }
      }
      
      return _isConfigured;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize keystroke authentication: $e');
      }
      _isConfigured = false;
      return false;
    }
  }
  
  /// Get automatic configuration based on platform
  static Map<String, dynamic> _getAutoConfiguration() {
    // Detect platform and return appropriate configuration
    if (kIsWeb) {
      return {
        'serverIp': PlatformKeystrokeConfig.web['server_ip'],
        'port': KeystrokeConfig.defaultPort,
        'useHttps': KeystrokeConfig.defaultUseHttps,
      };
    } else if (Platform.isAndroid) {
      // Check if running on emulator vs real device
      return {
        'serverIp': _isAndroidEmulator() ? 
            KeystrokeConfig.defaultAndroidEmulatorIp : 
            KeystrokeConfig.defaultServerIp,
        'port': KeystrokeConfig.defaultPort,
        'useHttps': KeystrokeConfig.defaultUseHttps,
      };
    } else if (Platform.isIOS) {
      return {
        'serverIp': PlatformKeystrokeConfig.ios['server_ip'],
        'port': KeystrokeConfig.defaultPort,
        'useHttps': KeystrokeConfig.defaultUseHttps,
      };
    } else {
      // Default configuration for other platforms
      return {
        'serverIp': KeystrokeConfig.defaultServerIp,
        'port': KeystrokeConfig.defaultPort,
        'useHttps': KeystrokeConfig.defaultUseHttps,
      };
    }
  }
  
  /// Simple heuristic to detect Android emulator
  /// Note: This is a basic implementation. In production, you might want more sophisticated detection.
  static bool _isAndroidEmulator() {
    // On Android emulator, the localhost/127.0.0.1 doesn't work for connecting to host machine
    // We need to use 10.0.2.2 which is the special IP for the host machine from emulator
    // For now, we'll assume emulator if we're in debug mode
    return kDebugMode;
  }
  
  /// Reinitialize the service (useful for testing or configuration changes)
  static Future<bool> reinitialize() async {
    _service = null;
    _isConfigured = false;
    return await initialize();
  }
  
  /// Get current configuration details
  static Map<String, dynamic>? getCurrentConfiguration() {
    if (!_isConfigured || _service == null) {
      return null;
    }
    
    return {
      'isConfigured': _isConfigured,
      'serverUrl': _service!.baseUrl,
      'isConnected': _isConfigured,
      'platform': _getCurrentPlatform(),
    };
  }
  
  /// Get current platform name
  static String _getCurrentPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android${_isAndroidEmulator() ? ' Emulator' : ' Device'}';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
  
  /// Test connection to the keystroke authentication server
  static Future<bool> testConnection() async {
    if (_service == null) {
      return false;
    }
    
    try {
      final isConnected = await _service!.testConnection();
      _isConfigured = isConnected;
      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('Connection test failed: $e');
      }
      _isConfigured = false;
      return false;
    }
  }
  
  /// Get connection status with details
  static Future<Map<String, dynamic>> getConnectionStatus() async {
    final config = _getAutoConfiguration();
    final serverUrl = KeystrokeConfig.getServerUrl(
      serverIp: config['serverIp'],
      port: config['port'],
      useHttps: config['useHttps'],
    );
    
    bool isConnected = false;
    String status = 'Not tested';
    
    if (_service != null) {
      try {
        isConnected = await _service!.testConnection();
        status = isConnected ? 'Connected' : 'Connection failed';
      } catch (e) {
        status = 'Error: $e';
      }
    }
    
    return {
      'serverUrl': serverUrl,
      'isConnected': isConnected,
      'status': status,
      'platform': _getCurrentPlatform(),
      'isConfigured': _isConfigured,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

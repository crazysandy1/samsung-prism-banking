import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/keystroke_models.dart';

/// Service class for communicating with the Keystroke Dynamics Authentication Backend
/// 
/// This service handles all API calls to the Flask backend for training
/// and authentication using keystroke dynamics.
class KeystrokeAuthService {
  static const String _defaultBaseUrl = 'http://localhost:5000';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  KeystrokeAuthService({
    String? baseUrl,
    Duration? timeout,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _defaultBaseUrl,
        timeout = timeout ?? _defaultTimeout,
        _client = client ?? http.Client();

  /// Health check endpoint to verify the backend is running
  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/health'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Train the user's keystroke model with new data
  Future<TrainingResponse> trainUser({
    required String userId,
    required List<KeystrokeEvent> keystrokeData,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'keystroke_data': keystrokeData.map((e) => e.toJson()).toList(),
      };

      final response = await _client
          .post(
            Uri.parse('$baseUrl/train'),
            headers: _getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TrainingResponse.fromJson(data);
      } else {
        throw KeystrokeAuthException(
          'Training failed: ${data['error'] ?? 'Unknown error'}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KeystrokeAuthException) rethrow;
      throw KeystrokeAuthException('Network error during training: $e');
    }
  }

  /// Authenticate user based on keystroke patterns
  Future<AuthenticationResponse> authenticateUser({
    required String userId,
    required List<KeystrokeEvent> keystrokeData,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'keystroke_data': keystrokeData.map((e) => e.toJson()).toList(),
      };

      final response = await _client
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: _getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthenticationResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        return AuthenticationResponse(
          authenticated: false,
          error: data['error'] ?? 'User model not found',
        );
      } else {
        throw KeystrokeAuthException(
          'Authentication failed: ${data['error'] ?? 'Unknown error'}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KeystrokeAuthException) rethrow;
      throw KeystrokeAuthException('Network error during authentication: $e');
    }
  }

  /// Get user training information and model status
  Future<UserTrainingInfo> getUserInfo(String userId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/user/$userId/info'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserTrainingInfo.fromJson(data);
      } else {
        throw KeystrokeAuthException(
          'Failed to get user info: ${data['error'] ?? 'Unknown error'}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KeystrokeAuthException) rethrow;
      throw KeystrokeAuthException('Network error while getting user info: $e');
    }
  }

  /// Test the API with sample data
  Future<bool> testConnection() async {
    try {
      // First check health
      if (!await healthCheck()) {
        return false;
      }

      // Try to get info for a test user (this should return 404 but confirms API is working)
      try {
        await getUserInfo('test_connection_user');
      } catch (e) {
        // Expected to fail for non-existent user
        if (e is KeystrokeAuthException && e.statusCode == 404) {
          return true; // API is working correctly
        }
      }

      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  /// Configure the service with a custom server URL
  /// Useful for connecting to different environments or local development
  static KeystrokeAuthService configure({
    required String serverIp,
    int port = 5000,
    bool useHttps = false,
    Duration? timeout,
  }) {
    final protocol = useHttps ? 'https' : 'http';
    final baseUrl = '$protocol://$serverIp:$port';
    
    return KeystrokeAuthService(
      baseUrl: baseUrl,
      timeout: timeout,
    );
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Dispose of the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Custom exception for keystroke authentication errors
class KeystrokeAuthException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  KeystrokeAuthException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'KeystrokeAuthException ($statusCode): $message';
    }
    return 'KeystrokeAuthException: $message';
  }

  bool get isNetworkError => statusCode == null;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
}

/// Configuration class for the keystroke service
class KeystrokeServiceConfig {
  final String serverIp;
  final int port;
  final bool useHttps;
  final Duration timeout;

  const KeystrokeServiceConfig({
    this.serverIp = 'localhost',
    this.port = 5000,
    this.useHttps = false,
    this.timeout = const Duration(seconds: 30),
  });

  String get baseUrl {
    final protocol = useHttps ? 'https' : 'http';
    return '$protocol://$serverIp:$port';
  }

  KeystrokeServiceConfig copyWith({
    String? serverIp,
    int? port,
    bool? useHttps,
    Duration? timeout,
  }) {
    return KeystrokeServiceConfig(
      serverIp: serverIp ?? this.serverIp,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      timeout: timeout ?? this.timeout,
    );
  }
}

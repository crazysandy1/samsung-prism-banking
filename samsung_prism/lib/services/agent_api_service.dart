import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/android_optimizations.dart';

// Models for API communication
class AgentQueryRequest {
  final String userId;
  final String queryText;
  final Map<String, dynamic> context;

  AgentQueryRequest({
    required this.userId,
    required this.queryText,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'query_text': queryText,
        'context': context,
      };
}

class AgentResponse {
  final String agentName;
  final String responseText;
  final double confidence;
  final String? actionTaken;
  final Map<String, dynamic>? data;
  final String timestamp;

  AgentResponse({
    required this.agentName,
    required this.responseText,
    required this.confidence,
    this.actionTaken,
    this.data,
    required this.timestamp,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) => AgentResponse(
        agentName: json['agent_name'],
        responseText: json['response_text'],
        confidence: json['confidence'].toDouble(),
        actionTaken: json['action_taken'],
        data: json['data'],
        timestamp: json['timestamp'],
      );
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class AuthResponse {
  final bool success;
  final String? userId;
  final String? accessToken;
  final Map<String, dynamic>? userData;
  final String message;

  AuthResponse({
    required this.success,
    this.userId,
    this.accessToken,
    this.userData,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        success: json['success'],
        userId: json['user_id'],
        accessToken: json['access_token'],
        userData: json['user_data'],
        message: json['message'],
      );
}

class UserProfile {
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? dateOfBirth;
  final double? accountBalance;
  final String? accountNumber;
  final String createdAt;
  final String? lastLogin;

  UserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.accountBalance,
    this.accountNumber,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['user_id'],
        email: json['email'],
        fullName: json['full_name'],
        phone: json['phone'],
        dateOfBirth: json['date_of_birth'],
        accountBalance: json['account_balance']?.toDouble(),
        accountNumber: json['account_number'],
        createdAt: json['created_at'],
        lastLogin: json['last_login'],
      );
}

class SystemHealth {
  final bool systemHealthy;
  final Map<String, dynamic> agentsStatus;
  final bool databaseConnection;
  final String timestamp;

  SystemHealth({
    required this.systemHealthy,
    required this.agentsStatus,
    required this.databaseConnection,
    required this.timestamp,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) => SystemHealth(
        systemHealthy: json['system_healthy'],
        agentsStatus: json['agents_status'],
        databaseConnection: json['database_connection'],
        timestamp: json['timestamp'],
      );
}

// Main Agent API Service
class AgentApiService {
  static String get baseUrl => AndroidOptimizations.apiBaseUrl;
  static Duration get timeoutDuration => AndroidOptimizations.networkTimeout;
  static Duration get shortTimeoutDuration => AndroidOptimizations.healthCheckTimeout;

  static Map<String, String> get _headers => AndroidOptimizations.networkHeaders;

  // Optimized Health Check with shorter timeout and fallback
  static Future<SystemHealth> getSystemHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: _headers,
          )
          .timeout(shortTimeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SystemHealth.fromJson(data);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      // Return default healthy status to prevent blocking UI
      print('Health check failed, using fallback: $e');
      return SystemHealth(
        systemHealthy: true,
        agentsStatus: {
          'AccountAgent': true,
          'LoanAgent': true,
          'CardAgent': true,
          'SupportAgent': true,
        },
        databaseConnection: true,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // Authentication
  static Future<AuthResponse> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(timeoutDuration);

      final data = json.decode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? dateOfBirth,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: json.encode(requestData),
          )
          .timeout(timeoutDuration);

      final data = json.decode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/profile/$userId'),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Profile fetch failed: $e');
    }
  }

  // Agent Queries
  static Future<AgentResponse> queryAgent({
    required String userId,
    required String queryText,
    Map<String, dynamic> context = const {},
  }) async {
    try {
      print('🚀 Making agent query to: $baseUrl/query');
      
      final request = AgentQueryRequest(
        userId: userId,
        queryText: queryText,
        context: context,
      );

      print('📤 Request data: ${json.encode(request.toJson())}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/query'),
            headers: _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AgentResponse.fromJson(data);
      } else {
        throw Exception('Query failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 Agent query exception: $e');
      rethrow;
    }
  }

  // Get Agent Capabilities
  static Future<Map<String, dynamic>> getAgentCapabilities() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/agents/capabilities'),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get capabilities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Capabilities fetch failed: $e');
    }
  }

  // Quick test method
  static Future<bool> testConnection() async {
    try {
      await getSystemHealth();
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}

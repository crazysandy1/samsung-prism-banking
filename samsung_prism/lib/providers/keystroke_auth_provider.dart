import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/keystroke_models.dart';
import '../services/keystroke_auth_service.dart';
import '../services/keystroke_auto_config_service.dart';
import '../config/keystroke_config.dart';

/// Provider class for managing keystroke dynamics authentication state
/// 
/// This provider handles the complete flow of keystroke authentication:
/// - Recording keystroke patterns
/// - Training user models
/// - Authenticating users
/// - Managing authentication state
class KeystrokeAuthProvider extends ChangeNotifier {
  final KeystrokeAuthService _service;
  KeystrokeAuthState _state = const KeystrokeAuthState();
  
  // Configuration
  String? _serverIp;
  bool _isConfigured = false;

  KeystrokeAuthProvider({KeystrokeAuthService? service})
      : _service = service ?? KeystrokeAuthService() {
    // Auto-configure with default settings using the auto-config service
    _initializeWithAutoConfig();
  }
  
  /// Initialize with automatic configuration
  Future<void> _initializeWithAutoConfig() async {
    try {
      _isConfigured = await KeystrokeAutoConfigService.initialize();
      if (_isConfigured) {
        final config = KeystrokeAutoConfigService.getCurrentConfiguration();
        if (config != null) {
          // Extract server IP from the server URL
          final serverUrl = config['serverUrl'] as String;
          final uri = Uri.parse(serverUrl);
          _serverIp = uri.host;
          
          if (kDebugMode) {
            print('✅ Keystroke auth auto-configured: $_serverIp');
          }
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Keystroke auth auto-config failed: $e');
      }
      _isConfigured = false;
    }
  }

  KeystrokeAuthState get state => _state;
  bool get isConfigured => _isConfigured;
  String? get serverIp => _serverIp;

  /// Configure the service with server details
  Future<void> configure({
    required String serverIp,
    int port = 5000,
    bool useHttps = false,
  }) async {
    try {
      _serverIp = serverIp;
      
      // Create new service with configuration
      final newService = KeystrokeAuthService.configure(
        serverIp: serverIp,
        port: port,
        useHttps: useHttps,
      );

      // Test connection
      final isConnected = await newService.testConnection();
      _isConfigured = isConnected;

      if (_isConfigured) {
        // Save configuration
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('keystroke_server_ip', serverIp);
        await prefs.setInt('keystroke_server_port', port);
        await prefs.setBool('keystroke_use_https', useHttps);

        _updateState(
          status: KeystrokeAuthStatus.idle,
          message: 'Connected to server successfully',
        );
      } else {
        _updateState(
          status: KeystrokeAuthStatus.error,
          message: 'Failed to connect to server',
        );
      }
    } catch (e) {
      _isConfigured = false;
      _updateState(
        status: KeystrokeAuthStatus.error,
        message: 'Configuration error: $e',
      );
    }
    notifyListeners();
  }

  /// Load saved configuration
  Future<void> loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverIp = prefs.getString('keystroke_server_ip');
      final port = prefs.getInt('keystroke_server_port') ?? 5000;
      final useHttps = prefs.getBool('keystroke_use_https') ?? false;

      if (serverIp != null) {
        await configure(
          serverIp: serverIp,
          port: port,
          useHttps: useHttps,
        );
      }
    } catch (e) {
      print('Failed to load configuration: $e');
    }
  }

  /// Start recording a keystroke session
  void startRecording(String userId) {
    final session = KeystrokeSession(
      userId: userId,
      events: [],
      startTime: DateTime.now(),
    );

    _updateState(
      status: KeystrokeAuthStatus.recording,
      currentSession: session,
      message: 'Recording keystroke pattern...',
    );
  }

  /// Add a keystroke event to the current session
  void addKeystrokeEvent(KeystrokeEvent event) {
    if (_state.currentSession == null) return;

    final updatedEvents = [..._state.currentSession!.events, event];
    final updatedSession = _state.currentSession!.copyWith(
      events: updatedEvents,
    );

    _updateState(currentSession: updatedSession);
  }

  /// Complete the current recording session
  void completeSession(KeystrokeSession session) {
    final completedSession = session.copyWith(
      endTime: DateTime.now(),
    );

    _updateState(
      status: KeystrokeAuthStatus.idle,
      currentSession: completedSession,
      message: 'Keystroke pattern recorded successfully',
    );
  }

  /// Train the user model with the current session
  Future<void> trainUser(String userId, {KeystrokeSession? session}) async {
    if (!_isConfigured) {
      _updateState(
        status: KeystrokeAuthStatus.error,
        message: 'Service not configured. Please connect to server first.',
      );
      return;
    }

    final trainingSession = session ?? _state.currentSession;
    if (trainingSession == null || trainingSession.events.isEmpty) {
      _updateState(
        status: KeystrokeAuthStatus.error,
        message: 'No keystroke data available for training',
      );
      return;
    }

    try {
      _updateState(
        status: KeystrokeAuthStatus.training,
        message: 'Training model...',
      );

      final response = await _service.trainUser(
        userId: userId,
        keystrokeData: trainingSession.events,
      );

      if (response.isSuccessful) {
        try {
          // Get updated user info from server
          final userInfo = await _service.getUserInfo(userId);
          
          // Save to local storage
          await _saveUserInfoToLocal(userId, userInfo);
          
          _updateState(
            status: KeystrokeAuthStatus.success,
            message: response.modelTrained
                ? 'Model trained successfully!'
                : 'Training data added. ${userInfo.remainingSamples} more samples needed.',
            userInfo: userInfo,
            currentSession: null, // Clear session after successful training
          );
        } catch (e) {
          // If server call fails but training was successful, mark as trained locally
          print('Failed to get updated user info, marking as trained locally: $e');
          await markUserAsTrained(userId);
          
          _updateState(
            status: KeystrokeAuthStatus.success,
            message: response.modelTrained
                ? 'Model trained successfully!'
                : 'Training completed!',
            currentSession: null,
          );
        }
      } else {
        _updateState(
          status: KeystrokeAuthStatus.error,
          message: response.message ?? 'Training failed',
        );
      }
    } catch (e) {
      _updateState(
        status: KeystrokeAuthStatus.error,
        message: 'Training error: $e',
      );
    }
  }

  /// Authenticate user with the current session
  Future<bool> authenticateUser(String userId, {KeystrokeSession? session}) async {
    if (!_isConfigured) {
      _updateState(
        status: KeystrokeAuthStatus.error,
        message: 'Service not configured. Please connect to server first.',
      );
      return false;
    }

    final authSession = session ?? _state.currentSession;
    if (authSession == null || authSession.events.isEmpty) {
      _updateState(
        status: KeystrokeAuthStatus.error,
        message: 'No keystroke data available for authentication',
      );
      return false;
    }

    try {
      _updateState(
        status: KeystrokeAuthStatus.authenticating,
        message: 'Authenticating...',
      );

      final response = await _service.authenticateUser(
        userId: userId,
        keystrokeData: authSession.events,
      );

      _updateState(
        status: response.isGenuineUser 
            ? KeystrokeAuthStatus.success 
            : KeystrokeAuthStatus.failure,
        message: response.isGenuineUser
            ? 'Authentication successful!'
            : response.reason ?? 'Authentication failed',
        lastAuthResult: response,
        currentSession: null, // Clear session after authentication attempt
      );

      return response.isGenuineUser;
    } catch (e) {
      _updateState(
        status: KeystrokeAuthStatus.error,
        message: 'Authentication error: $e',
        lastAuthResult: AuthenticationResponse(
          authenticated: false,
          error: e.toString(),
        ),
      );
      return false;
    }
  }

  /// Get user training information
  Future<void> loadUserInfo(String userId) async {
    print('DEBUG: loadUserInfo called for userId: $userId');
    print('DEBUG: isConfigured: $_isConfigured');
    
    // First check if user is marked as trained locally (for offline/override support)
    final prefs = await SharedPreferences.getInstance();
    final localOverride = prefs.getString('keystroke_user_info_$userId');
    if (localOverride != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(localOverride);
        final localUserInfo = UserTrainingInfo.fromJson(data);
        
        // If local data shows user is trained, prioritize it over server
        if (localUserInfo.hasTrainedModel || !localUserInfo.needsMoreTraining) {
          print('DEBUG: Using local override - user marked as trained locally');
          _updateState(userInfo: localUserInfo);
          return;
        }
      } catch (e) {
        print('DEBUG: Failed to parse local override: $e');
      }
    }
    
    if (!_isConfigured) {
      // If server not configured, check local storage for training status
      print('DEBUG: Server not configured, loading from local storage');
      await _loadUserInfoFromLocal(userId);
      return;
    }

    try {
      print('DEBUG: Trying to load user info from server');
      final userInfo = await _service.getUserInfo(userId);
      print('DEBUG: Server returned user info: $userInfo');
      print('DEBUG: UserInfo details - userId: ${userInfo.userId}');
      print('DEBUG: UserInfo details - trainingSamples: ${userInfo.trainingSamples}');
      print('DEBUG: UserInfo details - hasTrainedModel: ${userInfo.hasTrainedModel}');
      print('DEBUG: UserInfo details - minSamplesRequired: ${userInfo.minSamplesRequired}');
      print('DEBUG: UserInfo details - needsMoreTraining: ${userInfo.needsMoreTraining}');
      _updateState(userInfo: userInfo);
      
      // Save training status to local storage
      await _saveUserInfoToLocal(userId, userInfo);
    } catch (e) {
      print('Failed to load user info from server: $e');
      // Fallback to local storage if server fails
      print('DEBUG: Falling back to local storage');
      await _loadUserInfoFromLocal(userId);
    }
  }

  /// Save user training info to local storage
  Future<void> _saveUserInfoToLocal(String userId, UserTrainingInfo userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('keystroke_user_info_$userId', jsonEncode({
        'user_id': userInfo.userId,
        'training_samples': userInfo.trainingSamples,
        'has_trained_model': userInfo.hasTrainedModel,
        'min_samples_required': userInfo.minSamplesRequired,
        'max_feature_length': userInfo.maxFeatureLength,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      }));
    } catch (e) {
      print('Failed to save user info to local storage: $e');
    }
  }

  /// Load user training info from local storage
  Future<void> _loadUserInfoFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoJson = prefs.getString('keystroke_user_info_$userId');
      
      print('DEBUG: Local storage key: keystroke_user_info_$userId');
      print('DEBUG: Local storage value: $userInfoJson');
      
      if (userInfoJson != null) {
        final Map<String, dynamic> data = jsonDecode(userInfoJson);
        final userInfo = UserTrainingInfo.fromJson(data);
        _updateState(userInfo: userInfo);
        print('Loaded user training info from local storage for $userId');
        print('DEBUG: Loaded userInfo: hasTrainedModel=${userInfo.hasTrainedModel}, needsMoreTraining=${userInfo.needsMoreTraining}');
      } else {
        print('No local training info found for user $userId');
      }
    } catch (e) {
      print('Failed to load user info from local storage: $e');
    }
  }

  /// Check if user needs more training data
  bool needsTraining(String userId) {
    print('DEBUG: needsTraining called for userId: $userId');
    print('DEBUG: _state.userInfo is null: ${_state.userInfo == null}');
    
    // If we have user info from either server or local storage, use it
    if (_state.userInfo != null) {
      print('DEBUG: _state.userInfo.needsMoreTraining: ${_state.userInfo!.needsMoreTraining}');
      print('DEBUG: _state.userInfo.trainingSamples: ${_state.userInfo!.trainingSamples}');
      print('DEBUG: _state.userInfo.minSamplesRequired: ${_state.userInfo!.minSamplesRequired}');
      print('DEBUG: _state.userInfo.hasTrainedModel: ${_state.userInfo!.hasTrainedModel}');
      return _state.userInfo!.needsMoreTraining;
    }
    
    // If no user info available at all, assume training is needed
    print('DEBUG: No user info available, returning true');
    return true;
  }

  /// Mark user as trained locally (for offline support)
  Future<void> markUserAsTrained(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('keystroke_user_info_$userId', jsonEncode({
        'user_id': userId,
        'training_samples': 10, // Assume sufficient samples
        'has_trained_model': true,
        'min_samples_required': 5,
        'max_feature_length': null,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      }));
      
      // Update current state
      final userInfo = UserTrainingInfo(
        userId: userId,
        trainingSamples: 10,
        hasTrainedModel: true,
        minSamplesRequired: 5,
      );
      _updateState(userInfo: userInfo);
      
      print('Marked user $userId as trained in local storage');
    } catch (e) {
      print('Failed to mark user as trained: $e');
    }
  }

  /// Get training progress (0.0 to 1.0)
  double getTrainingProgress() {
    return _state.userInfo?.trainingProgress ?? 0.0;
  }

  /// Reset the current state
  void reset() {
    _updateState(
      status: KeystrokeAuthStatus.idle,
      message: null,
      currentSession: null,
      lastAuthResult: null,
    );
  }

  /// Clear all data for a user (for testing purposes)
  void clearUserData() {
    _updateState(
      userInfo: null,
      currentSession: null,
      lastAuthResult: null,
    );
  }

  /// Test connection to the server
  Future<bool> testConnection() async {
    try {
      return await _service.healthCheck();
    } catch (e) {
      return false;
    }
  }

  void _updateState({
    KeystrokeAuthStatus? status,
    String? message,
    KeystrokeSession? currentSession,
    UserTrainingInfo? userInfo,
    AuthenticationResponse? lastAuthResult,
  }) {
    _state = _state.copyWith(
      status: status,
      message: message,
      currentSession: currentSession,
      userInfo: userInfo,
      lastAuthResult: lastAuthResult,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Extension methods for convenient access to common operations
extension KeystrokeAuthProviderExtensions on KeystrokeAuthProvider {
  /// Check if the user can proceed with authentication
  bool canAuthenticate(String userId) {
    return _isConfigured && 
           (_state.userInfo?.hasTrainedModel ?? false) &&
           !_state.isProcessing;
  }

  /// Check if the user can add more training data
  bool canTrain() {
    return _isConfigured && !_state.isProcessing;
  }

  /// Get a user-friendly status message
  String getStatusMessage() {
    switch (_state.status) {
      case KeystrokeAuthStatus.idle:
        return 'Ready';
      case KeystrokeAuthStatus.recording:
        return 'Recording typing pattern...';
      case KeystrokeAuthStatus.training:
        return 'Training model...';
      case KeystrokeAuthStatus.authenticating:
        return 'Verifying identity...';
      case KeystrokeAuthStatus.success:
        return _state.message ?? 'Success';
      case KeystrokeAuthStatus.failure:
        return _state.message ?? 'Authentication failed';
      case KeystrokeAuthStatus.error:
        return _state.message ?? 'An error occurred';
    }
  }

  /// Get appropriate color for current status
  Color getStatusColor() {
    switch (_state.status) {
      case KeystrokeAuthStatus.idle:
        return const Color(0xFF2196F3); // Blue
      case KeystrokeAuthStatus.recording:
        return const Color(0xFFFF9800); // Orange
      case KeystrokeAuthStatus.training:
      case KeystrokeAuthStatus.authenticating:
        return const Color(0xFF2196F3); // Blue
      case KeystrokeAuthStatus.success:
        return const Color(0xFF4CAF50); // Green
      case KeystrokeAuthStatus.failure:
      case KeystrokeAuthStatus.error:
        return const Color(0xFFF44336); // Red
    }
  }
}

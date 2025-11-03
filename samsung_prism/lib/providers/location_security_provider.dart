/// Location Security Provider for Samsung Prism
/// 
/// This provider manages the state for location-based security features

import 'package:flutter/foundation.dart';
import '../models/location_security_models.dart';
import '../services/location_security_service.dart';

class LocationSecurityProvider extends ChangeNotifier {
  final LocationSecurityService _service = LocationSecurityService();
  
  // Current state
  UserLocation? _currentLocation;
  List<TrustedLocation> _trustedLocations = [];
  List<LoginAttempt> _recentLoginAttempts = [];
  List<SecurityAlert> _securityAlerts = [];
  int _unreadAlertsCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserLocation? get currentLocation => _currentLocation;
  List<TrustedLocation> get trustedLocations => _trustedLocations;
  List<LoginAttempt> get recentLoginAttempts => _recentLoginAttempts;
  List<SecurityAlert> get securityAlerts => _securityAlerts;
  int get unreadAlertsCount => _securityAlerts.where((alert) => !alert.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get current user location
  Future<UserLocation?> getCurrentLocation() async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentLocation = await _service.getCurrentLocation();
      
      _setLoading(false);
      return _currentLocation;
    } catch (e) {
      _setError('Failed to get current location: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Load user's trusted locations
  Future<void> loadTrustedLocations(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _trustedLocations = await _service.getTrustedLocations(userId);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load trusted locations: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Add a new trusted location
  Future<bool> addTrustedLocation({
    required String userId,
    required String name,
    UserLocation? location,
    double radiusKm = 5.0,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final locationToAdd = location ?? _currentLocation ?? await getCurrentLocation();
      if (locationToAdd == null) {
        _setError('Unable to get current location');
        _setLoading(false);
        return false;
      }

      await _service.addTrustedLocation(
        userId: userId,
        name: name,
        location: locationToAdd,
        radiusKm: radiusKm,
      );

      // Reload trusted locations
      await loadTrustedLocations(userId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add trusted location: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Remove a trusted location
  Future<bool> removeTrustedLocation({
    required String userId,
    required String locationId,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _service.removeTrustedLocation(
        userId: userId,
        locationId: locationId,
      );

      // Reload trusted locations
      await loadTrustedLocations(userId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to remove trusted location: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Record a login attempt
  Future<void> recordLoginAttempt({
    required String userId,
    required bool isSuccessful,
    String? authMethod,
  }) async {
    try {
      final location = await getCurrentLocation();
      if (location == null) return;

      await _service.recordLoginAttempt(
        userId: userId,
        location: location,
        isSuccessful: isSuccessful,
        authMethod: authMethod,
      );

      // Refresh data
      await loadRecentLoginAttempts(userId);
      await loadSecurityAlerts(userId);
    } catch (e) {
      print('Failed to record login attempt: $e');
    }
  }

  /// Load recent login attempts
  Future<void> loadRecentLoginAttempts(String userId) async {
    try {
      _recentLoginAttempts = await _service.getRecentLoginAttempts(userId);
      notifyListeners();
    } catch (e) {
      print('Failed to load login attempts: $e');
      // Don't fail the entire login process if we can't load recent attempts
      // Just set to empty list and continue
      _recentLoginAttempts = [];
      notifyListeners();
    }
  }

  /// Load security alerts
  Future<void> loadSecurityAlerts(String userId) async {
    try {
      _securityAlerts = await _service.getSecurityAlerts(userId);
      _unreadAlertsCount = await _service.getUnreadAlertsCount(userId);
      notifyListeners();
    } catch (e) {
      print('Failed to load security alerts: $e');
    }
  }

  /// Check transaction security
  Future<void> checkTransactionSecurity({
    required String userId,
    required double amount,
  }) async {
    try {
      await _service.checkTransactionSecurity(
        userId: userId,
        amount: amount,
        currentLocation: _currentLocation,
      );

      // Refresh alerts after check
      await loadSecurityAlerts(userId);
    } catch (e) {
      print('Failed to check transaction security: $e');
    }
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _service.markAlertAsRead(alertId);
      
      // Update local state
      final alertIndex = _securityAlerts.indexWhere((alert) => alert.id == alertId);
      if (alertIndex != -1) {
        _securityAlerts[alertIndex] = _securityAlerts[alertIndex].copyWith(
          isRead: true,
        );
        
        if (_unreadAlertsCount > 0) {
          _unreadAlertsCount--;
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Failed to mark alert as read: $e');
    }
  }

  /// Check if current location is trusted
  bool isCurrentLocationTrusted() {
    if (_currentLocation == null) return false;
    
    return _trustedLocations.any(
      (trusted) => trusted.isNear(_currentLocation!),
    );
  }

  /// Get nearest trusted location
  TrustedLocation? getNearestTrustedLocation() {
    if (_currentLocation == null || _trustedLocations.isEmpty) return null;
    
    TrustedLocation? nearest;
    double minDistance = double.infinity;
    
    for (final trusted in _trustedLocations) {
      final distance = _currentLocation!.distanceTo(trusted.location);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = trusted;
      }
    }
    
    return nearest;
  }

  /// Initialize location security for user
  Future<void> initializeForUser(String userId) async {
    await getCurrentLocation();
    await loadTrustedLocations(userId);
    await loadRecentLoginAttempts(userId);
    await loadSecurityAlerts(userId);
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (for logout)
  void clearData() {
    _currentLocation = null;
    _trustedLocations.clear();
    _recentLoginAttempts.clear();
    _securityAlerts.clear();
    _unreadAlertsCount = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

/// Location Security Service for Samsung Prism
/// 
/// This service handles all location-based security features including:
/// - Getting current user location
/// - Managing trusted locations
/// - Tracking login attempts
/// - Generating security alerts

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_security_models.dart';

class LocationSecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user location with address details
  Future<UserLocation?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      String? address;
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = '${placemark.street ?? ''} ${placemark.subLocality ?? ''}'.trim();
        }
      } catch (e) {
        print('Failed to get address: $e');
      }

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        displayName: address?.isNotEmpty == true ? address! : 'Unknown Location',
        address: address?.isNotEmpty == true ? address : null,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Failed to get current location: $e');
      return null;
    }
  }

  /// Get device information string
  Future<String> _getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return 'Web Browser';
      } else if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else if (Platform.isWindows) {
        return 'Windows Device';
      } else if (Platform.isMacOS) {
        return 'macOS Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Record a login attempt with location
  Future<void> recordLoginAttempt({
    required String userId,
    required UserLocation location,
    required bool isSuccessful,
    String? authMethod,
  }) async {
    try {
      // Check if location is trusted
      final trustedLocations = await getTrustedLocations(userId);
      final isTrustedLocation = trustedLocations.any(
        (trusted) => trusted.containsLocation(location),
      );

      final loginAttempt = LoginAttempt(
        id: _firestore.collection('login_attempts').doc().id,
        userId: userId,
        location: location,
        timestamp: DateTime.now(),
        wasSuccessful: isSuccessful,
        deviceInfo: await _getDeviceInfo(),
        ipAddress: null, // Can be populated if available
      );

      // Save login attempt
      await _firestore
          .collection('login_attempts')
          .doc(loginAttempt.id)
          .set(loginAttempt.toMap());

      // If successful login from untrusted location, create security alert
      if (isSuccessful && !isTrustedLocation) {
        await _createSecurityAlert(
          userId: userId,
          type: SecurityAlertType.suspicious_location,
          title: 'Login from New Location',
          message: 'You logged in from a new location: ${location.displayName}',
          location: location,
        );
      }

      print('Login attempt recorded: ${location.displayName}');
    } catch (e) {
      print('Failed to record login attempt: $e');
    }
  }

  /// Get user's trusted locations
  Future<List<TrustedLocation>> getTrustedLocations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trusted_locations')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => TrustedLocation.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Failed to get trusted locations: $e');
      return [];
    }
  }

  /// Add a new trusted location
  Future<void> addTrustedLocation({
    required String userId,
    required String name,
    required UserLocation location,
    double radiusKm = 5.0,
  }) async {
    try {
      final trustedLocation = TrustedLocation(
        id: '',
        userId: userId,
        name: name,
        location: location,
        createdAt: DateTime.now(),
        radiusKm: radiusKm,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trusted_locations')
          .add(trustedLocation.toMap());

      print('Trusted location added: $name');
    } catch (e) {
      print('Failed to add trusted location: $e');
      throw e;
    }
  }

  /// Remove a trusted location
  Future<void> removeTrustedLocation({
    required String userId,
    required String locationId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trusted_locations')
          .doc(locationId)
          .update({'isActive': false});

      print('Trusted location removed: $locationId');
    } catch (e) {
      print('Failed to remove trusted location: $e');
      throw e;
    }
  }

  /// Get recent login attempts for user
  Future<List<LoginAttempt>> getRecentLoginAttempts(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('login_attempts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => LoginAttempt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Handle the case where the Firestore index is still building
      if (e.toString().contains('failed-precondition') || 
          e.toString().contains('index') || 
          e.toString().contains('building')) {
        print('Firestore index is still building, using fallback query without orderBy');
        try {
          // Fallback: Query without orderBy (works without index)
          final snapshot = await _firestore
              .collection('login_attempts')
              .where('userId', isEqualTo: userId)
              .limit(limit)
              .get();

          var attempts = snapshot.docs
              .map((doc) => LoginAttempt.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Sort in memory since we can't use orderBy
          attempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return attempts;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }
      
      print('Failed to get login attempts: $e');
      return [];
    }
  }

  /// Create a security alert
  Future<void> _createSecurityAlert({
    required String userId,
    required SecurityAlertType type,
    required String title,
    required String message,
    UserLocation? location,
    double? transactionAmount,
  }) async {
    try {
      final alert = SecurityAlert(
        id: '',
        userId: userId,
        type: type,
        title: title,
        message: message,
        location: location,
        transactionAmount: transactionAmount,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('security_alerts')
          .add(alert.toMap());

      print('Security alert created: $title');
    } catch (e) {
      print('Failed to create security alert: $e');
    }
  }

  /// Check if transaction should trigger location-based alert
  Future<void> checkTransactionSecurity({
    required String userId,
    required double amount,
    UserLocation? currentLocation,
  }) async {
    try {
      // Only check for amounts > 2000
      if (amount <= 2000) return;

      UserLocation? location = currentLocation ?? await getCurrentLocation();
      if (location == null) return;

      // Check if current location is trusted
      final trustedLocations = await getTrustedLocations(userId);
      final isTrustedLocation = trustedLocations.any(
        (trusted) => trusted.containsLocation(location),
      );

      if (!isTrustedLocation) {
        await _createSecurityAlert(
          userId: userId,
          type: SecurityAlertType.high_amount_transaction,
          title: 'High-Value Transaction Alert',
          message: 'A transaction of ₹${amount.toStringAsFixed(2)} was attempted from an untrusted location: ${location.displayName}',
          location: location,
          transactionAmount: amount,
        );
      }
    } catch (e) {
      print('Failed to check transaction security: $e');
    }
  }

  /// Get user's security alerts
  Future<List<SecurityAlert>> getSecurityAlerts(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('security_alerts')
          .where('userId', isEqualTo: userId)
          .get();

      // Sort and limit in memory to avoid composite index requirement
      var alerts = snapshot.docs
          .map((doc) => SecurityAlert.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      // Sort by timestamp descending
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply limit
      if (alerts.length > limit) {
        alerts = alerts.take(limit).toList();
      }

      return alerts;
    } catch (e) {
      print('Failed to get security alerts: $e');
      return [];
    }
  }

  /// Mark security alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _firestore
          .collection('security_alerts')
          .doc(alertId)
          .update({'isRead': true});
    } catch (e) {
      print('Failed to mark alert as read: $e');
    }
  }

  /// Get unread security alerts count
  Future<int> getUnreadAlertsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('security_alerts')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Failed to get unread alerts count: $e');
      return 0;
    }
  }

  /// Stream of security alerts for real-time updates
  Stream<List<SecurityAlert>> streamSecurityAlerts(String userId) {
    return _firestore
        .collection('security_alerts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          var alerts = snapshot.docs
              .map((doc) => SecurityAlert.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Sort by timestamp descending
          alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          // Apply limit
          if (alerts.length > 50) {
            alerts = alerts.take(50).toList();
          }
          
          return alerts;
        });
  }
}

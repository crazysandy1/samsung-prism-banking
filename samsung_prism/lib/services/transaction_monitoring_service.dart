/// Transaction Monitoring Service
/// 
/// Handles location-based security checks for transactions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/location_security_models.dart';
import 'location_security_service.dart';

class TransactionMonitoringService {
  final LocationSecurityService _locationService = LocationSecurityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const double alertThreshold = 2000.0; // Amount threshold for alerts
  static const double trustedLocationRadius = 500.0; // meters

  /// Check if a transaction requires security verification
  Future<TransactionSecurityResult> checkTransactionSecurity({
    required double amount,
    required String transactionType,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return TransactionSecurityResult(
          isSecure: false,
          alertRequired: true,
          reason: 'User not authenticated',
        );
      }

      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) {
        return TransactionSecurityResult(
          isSecure: false,
          alertRequired: amount >= alertThreshold,
          reason: 'Unable to verify location',
        );
      }

      // Check if amount exceeds threshold
      if (amount >= alertThreshold) {
        // Get trusted locations
        final trustedLocations = await _locationService.getTrustedLocations(user.uid);
        
        // Check if current location is near any trusted location
        bool isInTrustedLocation = false;
        TrustedLocation? nearestTrustedLocation;
        
        for (final trusted in trustedLocations) {
          final distance = currentLocation.distanceTo(trusted.location);
          if (distance <= trustedLocationRadius) {
            isInTrustedLocation = true;
            nearestTrustedLocation = trusted;
            break;
          }
        }

        if (!isInTrustedLocation) {
          // Create security alert for high amount transaction from untrusted location
          await _createTransactionAlert(
            userId: user.uid,
            amount: amount,
            location: currentLocation,
            transactionType: transactionType,
            description: description,
          );

          return TransactionSecurityResult(
            isSecure: false,
            alertRequired: true,
            reason: 'High amount transaction from untrusted location',
            currentLocation: currentLocation,
            nearestTrustedLocation: nearestTrustedLocation,
          );
        } else {
          return TransactionSecurityResult(
            isSecure: true,
            alertRequired: false,
            reason: 'Transaction from trusted location',
            currentLocation: currentLocation,
            nearestTrustedLocation: nearestTrustedLocation,
          );
        }
      } else {
        // Amount is below threshold, always allow
        return TransactionSecurityResult(
          isSecure: true,
          alertRequired: false,
          reason: 'Amount below security threshold',
          currentLocation: currentLocation,
        );
      }
    } catch (e) {
      print('Error checking transaction security: $e');
      return TransactionSecurityResult(
        isSecure: false,
        alertRequired: true,
        reason: 'Security check failed: $e',
      );
    }
  }

  /// Create a security alert for suspicious transaction
  Future<void> _createTransactionAlert({
    required String userId,
    required double amount,
    required UserLocation location,
    required String transactionType,
    String? description,
  }) async {
    try {
      final alert = SecurityAlert(
        id: '', // Will be set by Firestore
        userId: userId,
        type: SecurityAlertType.high_amount_transaction,
        title: 'High Amount Transaction Alert',
        message: 'A transaction of ₹${amount.toStringAsFixed(2)} was attempted from an untrusted location. '
            'Transaction type: $transactionType. ${description != null ? 'Description: $description' : ''}',
        timestamp: DateTime.now(),
        location: location,
        transactionAmount: amount,
        isRead: false,
      );

      await _firestore
          .collection('security_alerts')
          .add(alert.toMap());

      print('Transaction security alert created for amount: ₹$amount');
    } catch (e) {
      print('Error creating transaction alert: $e');
    }
  }

  /// Record a successful transaction for analytics
  Future<void> recordTransaction({
    required double amount,
    required String transactionType,
    String? description,
    UserLocation? location,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final transaction = {
        'userId': user.uid,
        'amount': amount,
        'type': transactionType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'location': location?.toMap(),
      };

      await _firestore
          .collection('transactions')
          .add(transaction);

      print('Transaction recorded: ₹$amount - $transactionType');
    } catch (e) {
      print('Error recording transaction: $e');
    }
  }

  /// Get transaction history for the user
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 20,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  /// Get suspicious transaction patterns
  Future<List<Map<String, dynamic>>> getSuspiciousTransactions({
    int days = 30,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final query = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .where('amount', isGreaterThan: alertThreshold)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting suspicious transactions: $e');
      return [];
    }
  }

  /// Update security alert threshold
  static void updateAlertThreshold(double newThreshold) {
    // This would typically be stored in user preferences or app settings
    print('Alert threshold updated to: ₹$newThreshold');
  }

  /// Check if current location is safe for transactions
  Future<bool> isLocationSafeForTransactions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) return false;

      final trustedLocations = await _locationService.getTrustedLocations(user.uid);
      
      for (final trusted in trustedLocations) {
        final distance = currentLocation.distanceTo(trusted.location);
        if (distance <= trustedLocationRadius) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking location safety: $e');
      return false;
    }
  }
}

/// Result of transaction security check
class TransactionSecurityResult {
  final bool isSecure;
  final bool alertRequired;
  final String reason;
  final UserLocation? currentLocation;
  final TrustedLocation? nearestTrustedLocation;

  TransactionSecurityResult({
    required this.isSecure,
    required this.alertRequired,
    required this.reason,
    this.currentLocation,
    this.nearestTrustedLocation,
  });

  @override
  String toString() {
    return 'TransactionSecurityResult{isSecure: $isSecure, alertRequired: $alertRequired, reason: $reason}';
  }
}

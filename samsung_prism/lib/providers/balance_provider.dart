import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BalanceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  double _balance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  String _accountNumber = '';
  
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get accountNumber => _accountNumber;
  
  Future<void> fetchBalance() async {
    try {
      _setLoading(true);
      final User? user = _auth.currentUser;
      
      if (user != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _balance = (data['balance'] ?? 0.0).toDouble();
          _accountNumber = data['accountNumber'] ?? '';
          print('Balance fetched: $_balance'); // Debug log
        }
      }
      
      _setLoading(false);
      notifyListeners(); // Explicitly notify listeners after balance update
    } catch (e) {
      _setError('Failed to fetch balance');
      _setLoading(false);
    }
  }
  
  Future<bool> updateBalance(double newBalance) async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'balance': newBalance,
        });
        
        _balance = newBalance;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update balance');
      return false;
    }
  }

  /// Force refresh balance from Firebase (for real-time updates after transactions)
  Future<void> forceRefreshBalance() async {
    print('Force refreshing balance...');
    await fetchBalance();
    print('Force refresh completed. New balance: $_balance');
  }
  
  Future<bool> transferMoney(String recipientAccount, double amount, String description) async {
    try {
      _setLoading(true);
      
      if (amount > _balance) {
        _setError('Insufficient balance');
        _setLoading(false);
        return false;
      }
      
      // Find recipient by account number
      final QuerySnapshot recipientQuery = await _firestore
          .collection('users')
          .where('accountNumber', isEqualTo: recipientAccount)
          .get();
      
      if (recipientQuery.docs.isEmpty) {
        _setError('Recipient account not found');
        _setLoading(false);
        return false;
      }
      
      final recipientDoc = recipientQuery.docs.first;
      final recipientData = recipientDoc.data() as Map<String, dynamic>;
      final recipientBalance = (recipientData['balance'] ?? 0.0).toDouble();
      
      // Perform transfer
      final batch = _firestore.batch();
      
      // Update sender balance
      final User? user = _auth.currentUser;
      if (user != null) {
        batch.update(_firestore.collection('users').doc(user.uid), {
          'balance': _balance - amount,
        });
        
        // Update recipient balance
        batch.update(_firestore.collection('users').doc(recipientDoc.id), {
          'balance': recipientBalance + amount,
        });
        
        await batch.commit();
        
        _balance -= amount;
        notifyListeners();
        
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Transfer failed');
      _setLoading(false);
      return false;
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

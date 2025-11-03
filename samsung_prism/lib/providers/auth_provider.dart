import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }
  
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Add timeout for Android emulator performance
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'timeout',
            message: 'Authentication timeout. Please try again.',
          );
        },
      );
      
      _user = result.user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }
  
  Future<bool> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      _setLoading(true);
      _clearError();
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = result.user;
      
      // Create user profile in Firestore
      if (_user != null) {
        await _createUserProfile(fullName);
      }
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Error signing out');
    }
  }
  
  Future<void> _createUserProfile(String fullName) async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set({
        'fullName': fullName,
        'email': _user!.email,
        'accountNumber': _generateAccountNumber(),
        'balance': 10000.0, // Initial balance
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  String _generateAccountNumber() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
  }

  // Agent Authentication Method
  Future<bool> signInWithAgent({
    required String userId,
    required String email,
    required Map<String, dynamic> userData,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // For agent authentication, we'll create a custom User-like object
      // In production, you might want to integrate this with Firebase Auth
      
      // Store agent user data locally or in a state management solution
      // For now, we'll use the existing Firebase Auth structure
      
      // You could create a Firebase custom token here if needed
      // For demo purposes, we'll simulate authentication
      
      _agentUserId = userId;
      _agentUserData = userData;
      _isAgentAuthenticated = true;
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Agent authentication failed');
      _setLoading(false);
      return false;
    }
  }

  // Agent authentication state
  String? _agentUserId;
  Map<String, dynamic>? _agentUserData;
  bool _isAgentAuthenticated = false;
  
  String? get agentUserId => _agentUserId;
  Map<String, dynamic>? get agentUserData => _agentUserData;
  bool get isAgentAuthenticated => _isAgentAuthenticated;
  
  // Override the main authentication check to include agent auth
  bool get isAuthenticated => _user != null || _isAgentAuthenticated;
  
  // Get current user (Firebase or Agent)
  User? get currentUser => _user;
  String? get currentUserId => _user?.uid ?? _agentUserId;
  
  Future<void> signOutAgent() async {
    _agentUserId = null;
    _agentUserData = null;
    _isAgentAuthenticated = false;
    notifyListeners();
  }
  
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
  
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

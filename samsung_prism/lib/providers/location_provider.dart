import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String hours;
  final double distance;
  
  BankLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.hours,
    required this.distance,
  });
}

class LocationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Position? _currentPosition;
  String _currentAddress = '';
  List<BankLocation> _nearbyBranches = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _locationPermissionGranted = false;
  
  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  List<BankLocation> get nearbyBranches => _nearbyBranches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get locationPermissionGranted => _locationPermissionGranted;
  
  Future<bool> requestLocationPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // On mobile, prompt user to enable location services
        bool serviceEnabledAfterPrompt = await Geolocator.openLocationSettings();
        if (!serviceEnabledAfterPrompt) {
          _setError('Please enable location services in your device settings');
          return false;
        }
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      print('DEBUG: Current permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        print('DEBUG: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('DEBUG: Permission after request: $permission');
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('DEBUG: Location permissions permanently denied');
        _setError('Location permissions are permanently denied. Please enable them in app settings.');
        // On mobile, open app settings
        await Geolocator.openAppSettings();
        return false;
      }
      
      if (permission == LocationPermission.denied) {
        print('DEBUG: Location permissions denied');
        _setError('Location permissions are required for banking security features');
        return false;
      }
      
      print('DEBUG: Location permission granted: $permission');
      _locationPermissionGranted = true;
      clearError(); // Use existing clearError method
      notifyListeners();
      return true;
    } catch (e) {
      print('DEBUG: Error requesting location permission: $e');
      _setError('Failed to request location permission: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> getCurrentLocation() async {
    try {
      _setLoading(true);
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled');
        _setLoading(false);
        return false;
      }
      
      // Check permissions
      if (!_locationPermissionGranted) {
        bool permissionGranted = await requestLocationPermission();
        if (!permissionGranted) {
          _setLoading(false);
          return false;
        }
      }
      
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get address from coordinates
      await _getAddressFromCoordinates();
      
      // Save location to Firebase
      await _saveLocationToFirebase();
      
      // Find nearby branches
      await _findNearbyBranches();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to get current location');
      _setLoading(false);
      return false;
    }
  }
  
  Future<void> _getAddressFromCoordinates() async {
    try {
      if (_currentPosition != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _currentAddress = '${place.street}, ${place.locality}, ${place.country}';
        }
      }
    } catch (e) {
      _currentAddress = 'Address not available';
    }
  }
  
  Future<void> _saveLocationToFirebase() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null && _currentPosition != null) {
        await _firestore.collection('user_locations').doc(user.uid).set({
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'address': _currentAddress,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Silent fail for location saving
    }
  }
  
  Future<void> _findNearbyBranches() async {
    if (_currentPosition == null) return;
    
    // Sample bank branches (in a real app, this would come from a database)
    List<BankLocation> allBranches = [
      BankLocation(
        name: 'Samsung Prism Bank - Main Branch',
        address: '123 Financial District, City Center',
        latitude: _currentPosition!.latitude + 0.01,
        longitude: _currentPosition!.longitude + 0.01,
        phone: '+1-555-0123',
        hours: '9:00 AM - 5:00 PM',
        distance: 0,
      ),
      BankLocation(
        name: 'Samsung Prism Bank - Downtown',
        address: '456 Business Ave, Downtown',
        latitude: _currentPosition!.latitude - 0.02,
        longitude: _currentPosition!.longitude + 0.015,
        phone: '+1-555-0124',
        hours: '8:30 AM - 6:00 PM',
        distance: 0,
      ),
      BankLocation(
        name: 'Samsung Prism Bank - Mall Branch',
        address: '789 Shopping Mall, Sector 5',
        latitude: _currentPosition!.latitude + 0.025,
        longitude: _currentPosition!.longitude - 0.01,
        phone: '+1-555-0125',
        hours: '10:00 AM - 8:00 PM',
        distance: 0,
      ),
    ];
    
    // Calculate distances and sort
    for (var branch in allBranches) {
      branch = BankLocation(
        name: branch.name,
        address: branch.address,
        latitude: branch.latitude,
        longitude: branch.longitude,
        phone: branch.phone,
        hours: branch.hours,
        distance: Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          branch.latitude,
          branch.longitude,
        ) / 1000, // Convert to kilometers
      );
    }
    
    allBranches.sort((a, b) => a.distance.compareTo(b.distance));
    _nearbyBranches = allBranches.take(5).toList();
    notifyListeners();
  }
  
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
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

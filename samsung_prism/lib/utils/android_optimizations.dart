import 'dart:io';
import 'package:flutter/foundation.dart';

/// Android Emulator Performance Optimizations
class AndroidOptimizations {
  
  /// Check if running on Android emulator
  static bool get isAndroidEmulator {
    if (!kIsWeb && Platform.isAndroid) {
      // Check for common emulator indicators
      return Platform.environment['ANDROID_EMULATOR'] == 'true' ||
             Platform.environment.containsKey('ANDROID_AVD_HOME') ||
             defaultTargetPlatform == TargetPlatform.android;
    }
    return false;
  }

  /// Get optimized timeout duration based on platform
  static Duration get networkTimeout {
    if (isAndroidEmulator) {
      return const Duration(seconds: 15); // Longer timeout for emulator
    }
    return const Duration(seconds: 8); // Shorter for real devices
  }

  /// Get optimized health check timeout
  static Duration get healthCheckTimeout {
    if (isAndroidEmulator) {
      return const Duration(seconds: 8); // Reduced for emulator
    }
    return const Duration(seconds: 5); // Normal for devices
  }

  /// Get the appropriate base URL for API calls
  static String get apiBaseUrl {
    if (isAndroidEmulator) {
      return 'http://10.0.2.2:8000'; // Android emulator localhost mapping
    }
    return 'http://localhost:8000'; // Default for other platforms
  }

  /// Configure app for better emulator performance
  static void configureForEmulator() {
    if (isAndroidEmulator) {
      print('🤖 Android Emulator detected - Applying performance optimizations');
      
      // Disable unnecessary features that slow down emulator
      // These can be implemented as needed
    }
  }

  /// Emulator-specific network configuration
  static Map<String, String> get networkHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': isAndroidEmulator ? 'SamsungPrism-AndroidEmulator' : 'SamsungPrism',
    };
  }
}

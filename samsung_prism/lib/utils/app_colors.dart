import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);
  
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  static const Color accentGreen = Color(0xFF00C853);
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color accentPurple = Color(0xFF6A1B9A);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, secondaryBlue],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );
}

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF7A50); // Màu cam chính
  static const Color secondary = Color(0xFFFF9674);
  static const Color background = Color(0xFFFFFBF8); // Màu nền trắng kem
  static const Color white = Colors.white;
  static const Color black = Color(0xFF2D3748);
  static const Color grey = Color(0xFF718096);
  static const Color lightGrey = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFED8936);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF2196F3);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFFF6B35),
      Color(0xFFFF8A50),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
import 'package:flutter/material.dart';

class AppColors {
  // Minimalist Light Theme
  static const Color primaryColor = Colors.black; // Pure black
  static const Color accentColor = Colors.black; // Uber/Ola use black for accents too
  static const Color background = Colors.white;
  static const Color surfaceColor = Color(0xFFF7F7F7); // Light Grey
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color errorColor = Color(0xFFE53935);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Colors.black, Colors.black87],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800, // Thicker font
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Flat Box Decoration instead of Glassmorphism
  static final BoxDecoration glassBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
  
  static InputDecoration inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}

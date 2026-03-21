import 'package:flutter/material.dart';

/// Warna standar VernonEdu Student App.
class AppColors {
  AppColors._();

  // Primary — Deep Indigo (brand VernonEdu)
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF000051);
  static const Color primarySurface = Color(0xFFE8EAF6);

  // Accent — Cyan
  static const Color accent = Color(0xFF0097A7);
  static const Color accentLight = Color(0xFF00BCD4);
  static const Color accentSurface = Color(0xFFE0F7FA);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FE);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF0F0F0);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningSurface = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFC62828);
  static const Color errorSurface = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0277BD);
  static const Color infoSurface = Color(0xFFE1F5FE);

  // Field colors (course categories)
  static const Color fieldCoding = Color(0xFF1565C0);
  static const Color fieldCulinary = Color(0xFFE65100);
  static const Color fieldBarber = Color(0xFF2E7D32);
  static const Color fieldDesign = Color(0xFF6A1B9A);
  static const Color fieldMarketing = Color(0xFF00695C);

  // Grade colors
  static const Color gradeA = Color(0xFFFFD700);   // Gold
  static const Color gradeB = Color(0xFFC0C0C0);   // Silver
  static const Color gradeC = Color(0xFFCD7F32);   // Bronze

  // Gradient presets
  static const List<Color> gradientPrimary = [Color(0xFF1A237E), Color(0xFF3949AB)];
  static const List<Color> gradientAccent = [Color(0xFF0097A7), Color(0xFF00BCD4)];
  static const List<Color> gradientSuccess = [Color(0xFF2E7D32), Color(0xFF43A047)];
  static const List<Color> gradientWarm = [Color(0xFFE65100), Color(0xFFFF7043)];
}

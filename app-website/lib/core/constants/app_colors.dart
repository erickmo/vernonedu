import 'package:flutter/material.dart';

/// Palet warna VernonEdu Website — Light Modern Theme.
/// Mengikuti brand identity dari logo VernonEdu:
/// Background putih bersih, primary purple, accent blue/green/orange.
class AppColors {
  AppColors._();

  // ===== BACKGROUND =====
  static const Color bgPrimary = Color(0xFFF8F7FF);     // Lavender white
  static const Color bgSecondary = Color(0xFFF0EDF8);   // Light lavender
  static const Color bgCard = Color(0xFFFFFFFF);        // Pure white cards
  static const Color bgSurface = Color(0xFFEDE9F8);     // Soft lavender
  static const Color bgInput = Color(0xFFF5F2FF);       // Input background
  static const Color bgLavender = Color(0xFFCDC5E8);   // Lavender card (dari design)
  static const Color bgDarkSection = Color(0xFF3D2068); // Dark purple section (dari design)

  // ===== BRAND (matching VernonEdu logo) =====
  static const Color brandPurple = Color(0xFF7C68EE);   // Main purple logo
  static const Color brandViolet = Color(0xFF6C5CE7);   // Deep violet
  static const Color brandBlue = Color(0xFF3B90D9);     // Blue dari logo
  static const Color brandGreen = Color(0xFF00B894);    // Green dari logo
  static const Color brandOrange = Color(0xFFE17055);   // Orange/coral dari logo
  static const Color brandGold = Color(0xFFF59E0B);     // Gold accent
  static const Color brandRed = Color(0xFFEF4444);      // Red error

  // ===== BACKWARD COMPAT (alias) =====
  static const Color brandIndigo = brandPurple;
  static const Color brandVioletAlias = brandViolet;
  static const Color brandBlueAlias = brandBlue;

  // ===== TEXT =====
  static const Color textPrimary = Color(0xFF1E0A3C);   // Deep dark purple
  static const Color textSecondary = Color(0xFF5A4A7A); // Medium purple-gray
  static const Color textMuted = Color(0xFF9B8FB5);     // Muted purple
  static const Color textAccent = Color(0xFF6C5CE7);    // Accent violet
  static const Color textOnDark = Color(0xFFF8F7FF);    // Text on dark bg

  // ===== BORDER =====
  static const Color border = Color(0xFFE0D8F5);        // Light purple border
  static const Color borderLight = Color(0xFFEDE9F8);   // Very light border

  // ===== OVERLAY =====
  static const Color overlay = Color(0x40000000);
  static const Color glassBackground = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x60E0D8F5);

  // ===== STATUS =====
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B90D9);

  // ===== GRADIENTS =====
  static const Color gradientStart = Color(0xFF7C68EE);
  static const Color gradientEnd = Color(0xFF6C5CE7);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFF8F7FF), Color(0xFFEDE9F8), Color(0xFFF8F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lavenderGradient = LinearGradient(
    colors: [Color(0xFFD4C9F0), Color(0xFFC0B0E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF3D2068), Color(0xFF5B3A9A), Color(0xFF7C68EE)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradients untuk card warna warni (dari logo)
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF3B90D9), Color(0xFF2066B4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00967A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFE17055), Color(0xFFD35400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

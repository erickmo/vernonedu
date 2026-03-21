import 'package:flutter/material.dart';

/// Semua konstanta warna aplikasi.
///
/// Jangan gunakan [Color] literal di luar file ini.
abstract class AppColors {
  // — Brand
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5849D6);
  static const Color primaryLight = Color(0xFF9B8FF5);
  static const Color accent = Color(0xFF00CEFF);

  // — Background
  static const Color background = Color(0xFF0F0E17);
  static const Color surface = Color(0xFF1A1927);
  static const Color surfaceVariant = Color(0xFF252438);
  static const Color canvasBackground = Color(0xFF0A0914);
  static const Color canvasGrid = Color(0xFF18172A);

  // — Block Category Colors
  static const Color blockControl = Color(0xFFFF9F43);
  static const Color blockControlDark = Color(0xFFE8872B);
  static const Color blockIO = Color(0xFF54A0FF);
  static const Color blockIODark = Color(0xFF3880D4);
  static const Color blockVariable = Color(0xFFFF6B6B);
  static const Color blockVariableDark = Color(0xFFE05252);
  static const Color blockMath = Color(0xFFA29BFE);
  static const Color blockMathDark = Color(0xFF8578E0);
  static const Color blockLogic = Color(0xFF1DD1A1);
  static const Color blockLogicDark = Color(0xFF0BB88A);

  // — Status
  static const Color success = Color(0xFF1DD1A1);
  static const Color successLight = Color(0xFF1DD1A120);
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorLight = Color(0xFFFF6B6B20);
  static const Color warning = Color(0xFFFECA57);
  static const Color warningLight = Color(0xFFFECA5720);
  static const Color info = Color(0xFF54A0FF);

  // — Text
  static const Color textPrimary = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFFB2BEC3);
  static const Color textHint = Color(0xFF636E72);
  static const Color textDisabled = Color(0xFF4A4A5A);

  // — Border
  static const Color border = Color(0xFF2D2C3F);
  static const Color borderLight = Color(0xFF3D3C50);

  // — Code Preview
  static const Color codeBg = Color(0xFF0D1117);
  static const Color codeKeyword = Color(0xFFFF7B72);
  static const Color codeString = Color(0xFFA5D6FF);
  static const Color codeNumber = Color(0xFFF8C555);
  static const Color codeComment = Color(0xFF8B949E);
  static const Color codeFunction = Color(0xFFD2A8FF);

  // — Overlay
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
}

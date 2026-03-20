import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografi standar VernonEdu Website.
/// Poppins untuk heading, Inter untuk body. Warna disesuaikan dengan light theme.
class AppTextStyles {
  AppTextStyles._();

  // ===== DISPLAY (Hero section) =====
  static TextStyle get displayXL => GoogleFonts.poppins(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -2.0,
      );

  static TextStyle get displayL => GoogleFonts.poppins(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.15,
        letterSpacing: -1.5,
      );

  static TextStyle get displayM => GoogleFonts.poppins(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -1.0,
      );

  // ===== HEADING =====
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get h4 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ===== BODY =====
  static TextStyle get bodyL => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.7,
      );

  static TextStyle get bodyM => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.65,
      );

  static TextStyle get bodyS => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodyXS => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.5,
      );

  // ===== LABEL =====
  static TextStyle get labelL => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get labelM => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get labelS => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
        textBaseline: TextBaseline.alphabetic,
      );

  // ===== BADGE/TAG =====
  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );

  // ===== STAT NUMBER =====
  static TextStyle get statNumber => GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -1.5,
      );

  static TextStyle get statLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      );

  // ===== NAV =====
  static TextStyle get navLink => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get navLinkActive => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  // ===== BUTTON =====
  static TextStyle get btnL => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      );

  static TextStyle get btnM => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  // ===== ON DARK (untuk section gelap) =====
  static TextStyle get h1OnDark => h1.copyWith(color: AppColors.textOnDark);
  static TextStyle get h2OnDark => h2.copyWith(color: AppColors.textOnDark);
  static TextStyle get h3OnDark => h3.copyWith(color: AppColors.textOnDark);
  static TextStyle get bodyLOnDark => bodyL.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.8));
  static TextStyle get bodyMOnDark => bodyM.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.8));
  static TextStyle get labelMOnDark => labelM.copyWith(color: AppColors.textOnDark);
}

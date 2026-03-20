import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Left panel DashForge-style — gradient purple background
/// dengan branding, ilustrasi, dan decorative shapes.
class LoginLeftPanel extends StatelessWidget {
  const LoginLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          _buildDecorativeShapes(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildDecorativeShapes() {
    return Stack(
      children: [
        // Top-right circle
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Bottom-left circle
        Positioned(
          bottom: -80,
          left: -40,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
        ),
        // Mid-right small circle
        Positioned(
          top: 200,
          right: 40,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
          ),
        ),
        // Dotted pattern area
        Positioned(
          bottom: 120,
          right: 60,
          child: _buildDotPattern(),
        ),
      ],
    );
  }

  Widget _buildDotPattern() {
    return SizedBox(
      width: 80,
      height: 80,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 25,
        itemBuilder: (context, index) {
          return Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXXL,
        vertical: AppDimensions.spacingXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const Spacer(),
          _buildIllustration(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildTagline(),
          const Spacer(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          'vernon',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'edu',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 22,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Center(
      child: Container(
        width: 280,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'Entrepreneurship',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              'Your Business Journey Starts Here',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Belajar, Bangun, Kelola\nBisnis Kamu.',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          'Platform terpadu untuk siswa entrepreneurship.\n'
          'Dari ideation hingga operasional bisnis.',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      '\u00a9 2026 VernonEdu. All rights reserved.',
      style: GoogleFonts.inter(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
      ),
    );
  }
}

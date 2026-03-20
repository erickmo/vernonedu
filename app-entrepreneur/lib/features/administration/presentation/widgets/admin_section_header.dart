import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Section header widget for grouping admin features.
class AdminSectionHeader extends StatelessWidget {
  final String title;

  const AdminSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Container(
          height: 1,
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}

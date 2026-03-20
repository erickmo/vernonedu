import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Header section — badge label + judul + deskripsi.
/// Digunakan sebagai pembuka setiap section di homepage.
class SectionHeader extends StatelessWidget {
  final String badge;
  final String title;
  final String? subtitle;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;
  final bool isDark;

  const SectionHeader({
    super.key,
    required this.badge,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge
        _BadgeWidget(label: badge, isDark: isDark)
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 16),

        // Judul
        Text(
          title,
          style: isDark ? AppTextStyles.h1OnDark : AppTextStyles.h1,
          textAlign: textAlign,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0),

        if (subtitle != null) ...[
          const SizedBox(height: 16),
          Text(
            subtitle!,
            style: isDark ? AppTextStyles.bodyLOnDark : AppTextStyles.bodyL,
            textAlign: textAlign,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ],
    );
  }
}

/// Badge pill dengan gradient border.
class _BadgeWidget extends StatelessWidget {
  final String label;
  final bool isDark;

  const _BadgeWidget({required this.label, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.brandIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : AppColors.brandIndigo.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.badge.copyWith(
          color: isDark ? Colors.white : AppColors.textAccent,
        ),
      ),
    );
  }
}

/// Divider gradient horizontal.
class GradientDivider extends StatelessWidget {
  final double width;
  final double height;

  const GradientDivider({super.key, this.width = 60, this.height = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

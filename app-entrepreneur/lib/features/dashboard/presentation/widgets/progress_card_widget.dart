import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Learning progress item.
class ProgressItem {
  final String title;
  final String module;
  final double progress;
  final Color color;

  const ProgressItem({
    required this.title,
    required this.module,
    required this.progress,
    required this.color,
  });
}

/// DashForge-style progress card — learning progress overview.
class ProgressCardWidget extends StatelessWidget {
  const ProgressCardWidget({super.key});

  static const List<ProgressItem> _items = [
    ProgressItem(
      title: 'Business Model Canvas',
      module: '8 of 12 modules',
      progress: 0.67,
      color: AppColors.primary,
    ),
    ProgressItem(
      title: 'Marketing Strategy',
      module: '5 of 10 modules',
      progress: 0.50,
      color: Color(0xFF10B759),
    ),
    ProgressItem(
      title: 'Financial Planning',
      module: '3 of 8 modules',
      progress: 0.375,
      color: Color(0xFF0168FA),
    ),
    ProgressItem(
      title: 'HR Management',
      module: '1 of 6 modules',
      progress: 0.17,
      color: Color(0xFFFF6F00),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Column(
              children: _items
                  .map((item) => _buildProgressItem(item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Text(
            'Learning Progress',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // TODO: view all
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View All',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(ProgressItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(item.progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.module,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: item.color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }
}

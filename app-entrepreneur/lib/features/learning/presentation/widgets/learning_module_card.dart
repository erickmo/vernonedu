import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Learning module data model.
class LearningModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int totalLessons;
  final int completedLessons;
  final String duration;

  const LearningModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.totalLessons,
    required this.completedLessons,
    required this.duration,
  });

  double get progress =>
      totalLessons > 0 ? completedLessons / totalLessons : 0.0;

  bool get isCompleted => completedLessons >= totalLessons;

  bool get isNotStarted => completedLessons == 0;
}

/// Card untuk menampilkan satu modul pembelajaran.
class LearningModuleCard extends StatelessWidget {
  final LearningModule module;

  const LearningModuleCard({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(module.icon, color: module.color, size: 20),
              ),
              const Spacer(),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            module.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              module.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                module.duration,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.library_books_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${module.completedLessons}/${module.totalLessons}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: LinearProgressIndicator(
              value: module.progress,
              minHeight: 4,
              backgroundColor: module.color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(module.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final String label;
    final Color color;

    if (module.isCompleted) {
      label = 'Completed';
      color = AppColors.success;
    } else if (module.isNotStarted) {
      label = 'Not Started';
      color = AppColors.textMuted;
    } else {
      label = 'In Progress';
      color = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

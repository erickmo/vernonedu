import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

enum WorksheetStatus { notStarted, inProgress, completed }

/// Worksheet info data model.
class WorksheetInfo {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final WorksheetStatus status;
  final List<String> fields;

  const WorksheetInfo({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.status,
    required this.fields,
  });
}

/// Card worksheet dengan timeline indicator.
class WorksheetCardWidget extends StatelessWidget {
  final WorksheetInfo worksheet;
  final int stepNumber;
  final bool isLast;
  final VoidCallback onOpen;

  const WorksheetCardWidget({
    super.key,
    required this.worksheet,
    required this.stepNumber,
    required this.isLast,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeline(),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(child: _buildCard(context)),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final Color circleColor;
    final IconData circleIcon;

    switch (worksheet.status) {
      case WorksheetStatus.completed:
        circleColor = AppColors.success;
        circleIcon = Icons.check_rounded;
      case WorksheetStatus.inProgress:
        circleColor = AppColors.info;
        circleIcon = Icons.edit_rounded;
      case WorksheetStatus.notStarted:
        circleColor = AppColors.textMuted;
        circleIcon = Icons.circle_outlined;
    }

    return SizedBox(
      width: 36,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(circleIcon, color: Colors.white, size: 18),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: worksheet.status == WorksheetStatus.completed
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.divider,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: worksheet.status == WorksheetStatus.inProgress
              ? worksheet.color.withValues(alpha: 0.4)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
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
                  color: worksheet.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child:
                    Icon(worksheet.icon, color: worksheet.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tahap $stepNumber',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: worksheet.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      worksheet.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            worksheet.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          if (isDesktop) _buildFieldsPreview(),
          if (isDesktop) const SizedBox(height: AppDimensions.spacingM),
          SizedBox(
            width: isDesktop ? 180 : double.infinity,
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsPreview() {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: worksheet.fields.map((field) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            field,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge() {
    final String label;
    final Color color;

    switch (worksheet.status) {
      case WorksheetStatus.completed:
        label = 'Completed';
        color = AppColors.success;
      case WorksheetStatus.inProgress:
        label = 'In Progress';
        color = AppColors.info;
      case WorksheetStatus.notStarted:
        label = 'Not Started';
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (worksheet.status) {
      case WorksheetStatus.completed:
        return OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.visibility_rounded, size: 16),
          label: Text(
            'Review',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
          ),
        );
      case WorksheetStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: Text(
            'Lanjutkan',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );
      case WorksheetStatus.notStarted:
        return OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.play_arrow_rounded, size: 16),
          label: Text(
            'Mulai',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
        );
    }
  }
}

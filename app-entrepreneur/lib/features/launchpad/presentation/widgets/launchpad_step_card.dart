import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

enum StepStatus { notStarted, inProgress, completed }

/// Launchpad step info data model.
class LaunchpadStepInfo {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final StepStatus status;
  final List<String> checklist;

  const LaunchpadStepInfo({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.status,
    required this.checklist,
  });
}

/// Card per tahapan launchpad dengan timeline dan checklist preview.
class LaunchpadStepCard extends StatelessWidget {
  final LaunchpadStepInfo step;
  final int stepNumber;
  final bool isLast;
  final VoidCallback onOpen;

  const LaunchpadStepCard({
    super.key,
    required this.step,
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

    switch (step.status) {
      case StepStatus.completed:
        circleColor = AppColors.success;
        circleIcon = Icons.check_rounded;
      case StepStatus.inProgress:
        circleColor = AppColors.info;
        circleIcon = Icons.edit_rounded;
      case StepStatus.notStarted:
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
                color: step.status == StepStatus.completed
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.divider,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: step.status == StepStatus.inProgress
              ? step.color.withValues(alpha: 0.4)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          const SizedBox(height: 12),
          Text(
            step.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildChecklistPreview(),
          const SizedBox(height: AppDimensions.spacingM),
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Icon(step.icon, color: step.color, size: 20),
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
                  color: step.color,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                step.title,
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
    );
  }

  Widget _buildChecklistPreview() {
    final previewCount = step.checklist.length > 3 ? 3 : step.checklist.length;
    final remaining = step.checklist.length - previewCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklist (${step.checklist.length} items)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textLabel,
            ),
          ),
          const SizedBox(height: 8),
          ...step.checklist.take(previewCount).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    step.status == StepStatus.completed
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: step.status == StepStatus.completed
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        decoration: step.status == StepStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+$remaining more items...',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final String label;
    final Color color;

    switch (step.status) {
      case StepStatus.completed:
        label = 'Completed';
        color = AppColors.success;
      case StepStatus.inProgress:
        label = 'In Progress';
        color = AppColors.info;
      case StepStatus.notStarted:
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

  Widget _buildActionButton(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    final width = isDesktop ? 180.0 : double.infinity;

    switch (step.status) {
      case StepStatus.completed:
        return SizedBox(
          width: width,
          child: OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.visibility_rounded, size: 16),
            label: Text(
              'Review',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
            ),
          ),
        );
      case StepStatus.inProgress:
        return SizedBox(
          width: width,
          child: ElevatedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(
              'Lanjutkan',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        );
      case StepStatus.notStarted:
        return SizedBox(
          width: width,
          child: OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: Text(
              'Mulai',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side:
                  BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
          ),
        );
    }
  }
}

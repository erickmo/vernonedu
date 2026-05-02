import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Numbered step card used by certificate issue flows.
class IssueStepCard extends StatelessWidget {
  final int number;
  final String title;
  final Widget child;
  const IssueStepCard({
    super.key,
    required this.number,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(
                  '$number',
                  style: const TextStyle(
                      color: AppColors.textOnPrimary, fontSize: 12),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  )),
            ]),
            const SizedBox(height: AppDimensions.md),
            child,
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Tab riwayat kelas yang pernah diajar/diikuti SDM.
class SdmClassHistoryTabWidget extends StatelessWidget {
  final List<SdmClassHistoryEntity> classHistory;

  const SdmClassHistoryTabWidget({super.key, required this.classHistory});

  @override
  Widget build(BuildContext context) {
    if (classHistory.isEmpty) {
      return _buildEmpty(context);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        children: classHistory
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: _buildClassCard(context, c),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    SdmClassHistoryEntity cls,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(context, cls),
            const SizedBox(height: AppDimensions.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.sm),
            _buildCardMetrics(context, cls),
          ],
        ),
      );

  Widget _buildCardHeader(
    BuildContext context,
    SdmClassHistoryEntity cls,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(
              Icons.class_outlined,
              color: AppColors.primary,
              size: AppDimensions.iconMd,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.courseName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  cls.batchName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppDimensions.xs),
                _buildRoleChip(context, cls.roleInClass),
              ],
            ),
          ),
          _buildDateRange(context, cls),
        ],
      );

  Widget _buildRoleChip(BuildContext context, SdmRole role) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(
          role.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  Widget _buildDateRange(BuildContext context, SdmClassHistoryEntity cls) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _fmtDate(cls.startDate),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          if (cls.endDate != null)
            Text(
              '— ${_fmtDate(cls.endDate!)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
        ],
      );

  Widget _buildCardMetrics(
    BuildContext context,
    SdmClassHistoryEntity cls,
  ) =>
      Row(
        children: [
          _buildMetric(
            context,
            Icons.people_outlined,
            '${cls.studentCount}',
            AppStrings.sdmClassStudents,
            AppColors.primary,
          ),
          if (cls.completionRate != null) ...[
            const SizedBox(width: AppDimensions.lg),
            _buildMetric(
              context,
              Icons.check_circle_outline,
              '${cls.completionRate!.toStringAsFixed(0)}%',
              AppStrings.sdmClassCompletion,
              AppColors.success,
            ),
          ],
          if (cls.rating != null) ...[
            const SizedBox(width: AppDimensions.lg),
            _buildMetric(
              context,
              Icons.star_outline,
              cls.rating!.toStringAsFixed(1),
              AppStrings.sdmClassRating,
              AppColors.warning,
            ),
          ],
        ],
      );

  Widget _buildMetric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) =>
      Row(
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: color),
          const SizedBox(width: AppDimensions.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ],
      );

  Widget _buildEmpty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.class_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                AppStrings.sdmNoClassData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

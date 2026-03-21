import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Header profil SDM — avatar, nama, role badge, kontak, quick stats.
class SdmProfileHeaderWidget extends StatelessWidget {
  final SdmDetailEntity detail;

  const SdmProfileHeaderWidget({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(context),
          const SizedBox(height: AppDimensions.lg),
          _buildStatsRow(context),
        ],
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(context),
          const SizedBox(width: AppDimensions.lg),
          Expanded(child: _buildInfo(context)),
          _buildStatusBadge(context),
        ],
      );

  Widget _buildAvatar(BuildContext context) => Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primarySurface,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: detail.photoUrl != null
            ? ClipOval(
                child: Image.network(
                  detail.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildAvatarFallback(context),
                ),
              )
            : _buildAvatarFallback(context),
      );

  Widget _buildAvatarFallback(BuildContext context) => Center(
        child: Text(
          detail.name.isNotEmpty ? detail.name[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );

  Widget _buildInfo(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          _buildRoleBadge(context),
          const SizedBox(height: AppDimensions.sm),
          _buildContactRow(context),
        ],
      );

  Widget _buildRoleBadge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
        ),
        child: Text(
          detail.role.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  Widget _buildContactRow(BuildContext context) => Wrap(
        spacing: AppDimensions.md,
        runSpacing: AppDimensions.xs,
        children: [
          _buildContactItem(context, Icons.email_outlined, detail.email),
          if (detail.phone != null)
            _buildContactItem(context, Icons.phone_outlined, detail.phone!),
          if (detail.department != null)
            _buildContactItem(
                context, Icons.business_outlined, detail.department!),
          _buildContactItem(
            context,
            Icons.calendar_today_outlined,
            'Bergabung ${_formatYear(detail.joinDate)}',
          ),
        ],
      );

  Widget _buildContactItem(
          BuildContext context, IconData icon, String text) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.xs),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      );

  Widget _buildStatusBadge(BuildContext context) {
    final isActive = detail.status == SdmStatus.active;
    final isOnLeave = detail.status == SdmStatus.onLeave;
    final color =
        isActive ? AppColors.success : isOnLeave ? AppColors.warning : AppColors.textHint;
    final bgColor = isActive
        ? AppColors.successSurface
        : isOnLeave
            ? AppColors.warningSurface
            : AppColors.border;
    final label = isActive
        ? AppStrings.sdmStatusActive
        : isOnLeave
            ? AppStrings.sdmStatusOnLeave
            : AppStrings.sdmStatusInactive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: AppDimensions.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) => Row(
        children: [
          _buildStatItem(
            context,
            Icons.school_outlined,
            '${detail.stats.totalStudents}',
            AppStrings.sdmStatStudents,
            AppColors.primary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            context,
            Icons.layers_outlined,
            '${detail.stats.totalPrograms}',
            AppStrings.sdmStatPrograms,
            AppColors.secondary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            context,
            Icons.star_outline,
            detail.stats.averageRating > 0
                ? detail.stats.averageRating.toStringAsFixed(1)
                : '-',
            AppStrings.sdmStatRating,
            AppColors.warning,
          ),
          _buildStatDivider(),
          _buildStatItem(
            context,
            Icons.trending_up,
            '${detail.stats.completionRate.toStringAsFixed(0)}%',
            AppStrings.sdmStatCompletion,
            AppColors.success,
          ),
          _buildStatDivider(),
          _buildStatItem(
            context,
            Icons.work_history_outlined,
            '${detail.stats.yearsActive} thn',
            AppStrings.sdmStatYearsActive,
            AppColors.info,
          ),
        ],
      );

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) =>
      Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: AppDimensions.iconMd, color: color),
                const SizedBox(width: AppDimensions.xs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
              ],
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );

  Widget _buildStatDivider() => Container(
        height: 36,
        width: 1,
        color: AppColors.border,
      );

  String _formatYear(DateTime date) {
    return '${date.year}';
  }
}

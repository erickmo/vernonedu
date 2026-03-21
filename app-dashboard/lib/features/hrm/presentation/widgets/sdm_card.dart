import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Kartu SDM untuk tampilan daftar — nama, role, stats, status.
class SdmCard extends StatelessWidget {
  final SdmEntity sdm;
  final VoidCallback onTap;

  const SdmCard({
    super.key,
    required this.sdm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: AppDimensions.md),
            Expanded(child: _buildInfo(context)),
            const SizedBox(width: AppDimensions.md),
            _buildStats(context),
            const SizedBox(width: AppDimensions.md),
            _buildStatusBadge(context),
            const SizedBox(width: AppDimensions.sm),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: AppDimensions.iconMd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) => Container(
        width: AppDimensions.avatarLg,
        height: AppDimensions.avatarLg,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primarySurface,
          border: Border.all(color: AppColors.border),
        ),
        child: sdm.photoUrl != null
            ? ClipOval(
                child: Image.network(
                  sdm.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildInitial(context),
                ),
              )
            : _buildInitial(context),
      );

  Widget _buildInitial(BuildContext context) => Center(
        child: Text(
          sdm.name.isNotEmpty ? sdm.name[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );

  Widget _buildInfo(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sdm.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          _buildRoleBadge(context),
          const SizedBox(height: AppDimensions.xs),
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                size: AppDimensions.iconSm,
                color: AppColors.textHint,
              ),
              const SizedBox(width: AppDimensions.xs),
              Text(
                sdm.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (sdm.department != null) ...[
                const SizedBox(width: AppDimensions.sm),
                Icon(
                  Icons.business_outlined,
                  size: AppDimensions.iconSm,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: AppDimensions.xs),
                Text(
                  sdm.department!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ],
      );

  Widget _buildRoleBadge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(
          sdm.role.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  Widget _buildStats(BuildContext context) => Row(
        children: [
          _buildStatItem(
            context,
            Icons.people_outlined,
            '${sdm.totalStudentsTaught}',
            AppStrings.sdmStatStudents,
          ),
          const SizedBox(width: AppDimensions.md),
          _buildStatItem(
            context,
            Icons.layers_outlined,
            '${sdm.totalPrograms}',
            AppStrings.sdmStatPrograms,
          ),
          if (sdm.rating != null) ...[
            const SizedBox(width: AppDimensions.md),
            _buildStatItem(
              context,
              Icons.star_outline,
              sdm.rating!.toStringAsFixed(1),
              AppStrings.sdmStatRating,
            ),
          ],
        ],
      );

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) =>
      Column(
        children: [
          Row(
            children: [
              Icon(icon, size: AppDimensions.iconSm, color: AppColors.textHint),
              const SizedBox(width: AppDimensions.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      );

  Widget _buildStatusBadge(BuildContext context) {
    final isActive = sdm.status == SdmStatus.active;
    final isOnLeave = sdm.status == SdmStatus.onLeave;
    final color = isActive
        ? AppColors.success
        : isOnLeave
            ? AppColors.warning
            : AppColors.textHint;
    final bgColor = isActive
        ? AppColors.successSurface
        : isOnLeave
            ? AppColors.warningSurface
            : AppColors.surfaceVariant;
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
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Tab program SDM — daftar program dimana SDM berperan sebagai creator/mentor/fasilitator.
class SdmProgramTabWidget extends StatelessWidget {
  final List<SdmProgramEntity> programs;

  const SdmProgramTabWidget({super.key, required this.programs});

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return _buildEmpty(context);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: programs
            .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: _buildProgramCard(context, p),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, SdmProgramEntity program) =>
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
            Row(
              children: [
                Expanded(child: _buildProgramHeader(context, program)),
                _buildStatusBadge(context, program.status),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.sm),
            _buildProgramMeta(context, program),
          ],
        ),
      );

  Widget _buildProgramHeader(
    BuildContext context,
    SdmProgramEntity program,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.programName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          _buildRoleBadge(context, program.roleInProgram),
        ],
      );

  Widget _buildRoleBadge(BuildContext context, SdmRole role) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final isActive = status == 'active';
    final isUpcoming = status == 'upcoming';
    final color = isActive
        ? AppColors.success
        : isUpcoming
            ? AppColors.info
            : AppColors.textHint;
    final bgColor = isActive
        ? AppColors.successSurface
        : isUpcoming
            ? AppColors.infoSurface
            : AppColors.surfaceVariant;
    final label = isActive
        ? AppStrings.sdmProgramStatusActive
        : isUpcoming
            ? AppStrings.sdmProgramStatusUpcoming
            : AppStrings.sdmProgramStatusCompleted;

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

  Widget _buildProgramMeta(BuildContext context, SdmProgramEntity program) =>
      Wrap(
        spacing: AppDimensions.md,
        runSpacing: AppDimensions.xs,
        children: [
          _buildMetaItem(
            context,
            Icons.category_outlined,
            program.courseTypeName,
          ),
          if (program.batchName != null)
            _buildMetaItem(
              context,
              Icons.group_work_outlined,
              program.batchName!,
            ),
          _buildMetaItem(
            context,
            Icons.date_range_outlined,
            program.endDate != null
                ? '${_fmtDate(program.startDate)} — ${_fmtDate(program.endDate!)}'
                : 'Mulai ${_fmtDate(program.startDate)}',
          ),
          if (program.studentCount != null)
            _buildMetaItem(
              context,
              Icons.people_outlined,
              '${program.studentCount} peserta',
            ),
        ],
      );

  Widget _buildMetaItem(
    BuildContext context,
    IconData icon,
    String text,
  ) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: AppColors.textHint),
          const SizedBox(width: AppDimensions.xs),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                Icons.layers_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                AppStrings.sdmNoProgramData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );

  Color _roleColor(SdmRole role) {
    switch (role) {
      case SdmRole.courseCreator:
        return AppColors.roleDirector;
      case SdmRole.facilitator:
        return AppColors.roleFacilitator;
      case SdmRole.headOfProgram:
        return AppColors.primary;
      case SdmRole.coordinator:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

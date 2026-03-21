import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../batch/domain/entities/batch_entity.dart';
import '../../../batch/presentation/cubit/batch_detail_cubit.dart';
import '../../../batch/presentation/cubit/batch_detail_state.dart';
import '../../domain/entities/facilitator_entity.dart';
import '../cubit/assignment_cubit.dart';
import '../cubit/assignment_state.dart';

class AssignFacilitatorPage extends StatelessWidget {
  final String batchId;
  final BatchEntity batch;

  const AssignFacilitatorPage({
    super.key,
    required this.batchId,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AssignmentCubit>()..loadFacilitators(),
        ),
        BlocProvider(
          create: (_) => getIt<BatchDetailCubit>()..loadDetail(batchId),
        ),
      ],
      child: _AssignFacilitatorView(batchId: batchId, batch: batch),
    );
  }
}

class _AssignFacilitatorView extends StatelessWidget {
  final String batchId;
  final BatchEntity batch;

  const _AssignFacilitatorView({
    required this.batchId,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<BatchDetailCubit, BatchDetailState>(
      listener: (context, state) {
        if (state is BatchDetailLoaded && !state.isAssigning) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.facilitatorAssigned),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.assignFacilitatorTitle),
          backgroundColor: AppColors.surface,
        ),
        body: Column(
          children: [
            _buildBatchInfo(context),
            Expanded(child: _buildFacilitatorList(context)),
          ],
        ),
        bottomNavigationBar: _buildAssignButton(context),
      ),
    );
  }

  Widget _buildBatchInfo(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.class_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.masterCourseName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    batch.code,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFacilitatorList(BuildContext context) {
    return BlocBuilder<AssignmentCubit, AssignmentState>(
      builder: (context, state) {
        if (state is AssignmentLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AssignmentError) {
          return ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<AssignmentCubit>().loadFacilitators(),
          );
        }
        if (state is AssignmentLoaded) {
          if (state.facilitators.isEmpty) {
            return const EmptyView(
              icon: Icons.person_search_outlined,
              message: AppStrings.noFacilitators,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            itemCount: state.facilitators.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.xs),
            itemBuilder: (context, i) => _FacilitatorTile(
              facilitator: state.facilitators[i],
              isSelected: state.selectedId == state.facilitators[i].id,
              currentFacilitatorId: batch.facilitatorId,
              onTap: () => context
                  .read<AssignmentCubit>()
                  .selectFacilitator(state.facilitators[i].id),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildAssignButton(BuildContext context) {
    return BlocBuilder<AssignmentCubit, AssignmentState>(
      builder: (context, assignState) {
        return BlocBuilder<BatchDetailCubit, BatchDetailState>(
          builder: (context, detailState) {
            final selectedId = assignState is AssignmentLoaded
                ? assignState.selectedId
                : null;
            final isAssigning = detailState is BatchDetailLoaded
                ? detailState.isAssigning
                : false;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: ElevatedButton(
                  onPressed: selectedId == null || isAssigning
                      ? null
                      : () => context
                          .read<BatchDetailCubit>()
                          .assignFacilitator(batchId, selectedId),
                  child: isAssigning
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Text(AppStrings.assignFacilitatorTitle),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FacilitatorTile extends StatelessWidget {
  final FacilitatorEntity facilitator;
  final bool isSelected;
  final String? currentFacilitatorId;
  final VoidCallback onTap;

  const _FacilitatorTile({
    required this.facilitator,
    required this.isSelected,
    required this.currentFacilitatorId,
    required this.onTap,
  });

  bool get isCurrent => facilitator.id == currentFacilitatorId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppDimensions.avatarSm / 2,
              backgroundColor: isSelected
                  ? AppColors.primary
                  : AppColors.primarySurface,
              child: Text(
                facilitator.initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        facilitator.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: AppDimensions.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusCircle),
                          ),
                          child: const Text(
                            'Saat Ini',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.success),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    facilitator.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (facilitator.departmentName != null)
                    Text(
                      facilitator.departmentName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${facilitator.activeBatchCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'kelas aktif',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/batch_entity.dart';
import '../cubit/batch_list_cubit.dart';
import '../cubit/batch_list_state.dart';

class BatchListPage extends StatelessWidget {
  const BatchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myBatches),
        backgroundColor: AppColors.surface,
      ),
      body: BlocBuilder<BatchListCubit, BatchListState>(
        builder: (context, state) {
          if (state is BatchListInitial) {
            context.read<BatchListCubit>().loadBatches();
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BatchListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BatchListError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<BatchListCubit>().loadBatches(),
            );
          }
          if (state is BatchListLoaded) {
            return _BatchListBody(batches: state.batches);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BatchListBody extends StatefulWidget {
  final List<BatchEntity> batches;

  const _BatchListBody({required this.batches});

  @override
  State<_BatchListBody> createState() => _BatchListBodyState();
}

class _BatchListBodyState extends State<_BatchListBody> {
  String _filter = 'all'; // all | active | completed

  List<BatchEntity> get _filtered {
    if (_filter == 'active') {
      return widget.batches.where((b) => b.isActive).toList();
    }
    if (_filter == 'completed') {
      return widget.batches.where((b) => b.status == 'completed').toList();
    }
    return widget.batches;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<BatchListCubit>().loadBatches(),
      child: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyView(
                    icon: Icons.class_outlined,
                    message: AppStrings.noBatches,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.pagePadding),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.sm),
                    itemBuilder: (context, i) => _BatchCard(
                      batch: _filtered[i],
                      onTap: () =>
                          context.push('/batches/${_filtered[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua',
              selected: _filter == 'all',
              onTap: () => setState(() => _filter = 'all'),
            ),
            const SizedBox(width: AppDimensions.sm),
            _FilterChip(
              label: 'Aktif',
              selected: _filter == 'active',
              color: AppColors.success,
              onTap: () => setState(() => _filter = 'active'),
            ),
            const SizedBox(width: AppDimensions.sm),
            _FilterChip(
              label: 'Selesai',
              selected: _filter == 'completed',
              color: AppColors.textSecondary,
              onTap: () => setState(() => _filter = 'completed'),
            ),
          ],
        ),
      );
}

class _BatchCard extends StatelessWidget {
  final BatchEntity batch;
  final VoidCallback onTap;

  const _BatchCard({required this.batch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppDimensions.sm),
            _buildMeta(context),
            const SizedBox(height: AppDimensions.md),
            _buildProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              batch.masterCourseName,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          _StatusBadge(status: batch.status, label: batch.statusLabel),
        ],
      );

  Widget _buildMeta(BuildContext context) => Row(
        children: [
          const Icon(Icons.tag_rounded,
              size: AppDimensions.iconSm, color: AppColors.textHint),
          const SizedBox(width: AppDimensions.xs),
          Text(batch.code,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: AppDimensions.md),
          const Icon(Icons.people_outlined,
              size: AppDimensions.iconSm, color: AppColors.textHint),
          const SizedBox(width: AppDimensions.xs),
          Text('${batch.totalEnrolled} siswa',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppDimensions.md),
          const Icon(Icons.calendar_today_outlined,
              size: AppDimensions.iconSm, color: AppColors.textHint),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: Text(
              '${DateUtil.toDisplay(batch.startDate)} – ${DateUtil.toDisplay(batch.endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _buildProgress() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sesi ${batch.completedSessions}/${batch.totalSessions}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                '${(batch.progressPercent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: batch.progressPercent,
              backgroundColor: AppColors.primarySurface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case 'active':
        bg = AppColors.successSurface;
        fg = AppColors.success;
        break;
      case 'completed':
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        break;
      default:
        bg = AppColors.infoSurface;
        fg = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : AppColors.surfaceVariant,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusCircle),
          border: Border.all(
              color: selected ? c : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

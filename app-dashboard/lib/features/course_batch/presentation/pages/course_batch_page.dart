import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/course_batch_entity.dart';
import '../cubit/course_batch_cubit.dart';
import '../cubit/course_batch_state.dart';

class CourseBatchPage extends StatelessWidget {
  const CourseBatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseBatchCubit>()..loadBatches(),
      child: const _CourseBatchView(),
    );
  }
}

class _CourseBatchView extends StatefulWidget {
  const _CourseBatchView();

  @override
  State<_CourseBatchView> createState() => _CourseBatchViewState();
}

class _CourseBatchViewState extends State<_CourseBatchView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'semua'; // semua | upcoming | ongoing | completed

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CourseBatchEntity> _filtered(List<CourseBatchEntity> batches) {
    var list = batches;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((b) =>
              b.code.toLowerCase().contains(q) ||
              b.masterCourseName.toLowerCase().contains(q))
          .toList();
    }
    if (_statusFilter != 'semua') {
      list = list.where((b) => b.status == _statusFilter).toList();
    }
    return list;
  }

  Future<void> _showCreateForm() async {
    final created = await context.push<bool>('/course-batches/new');
    if (created == true && context.mounted) {
      context.read<CourseBatchCubit>().loadBatches();
    }
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required String filterKey,
    required Color color,
    required Color surfaceColor,
  }) {
    final isSelected = _statusFilter == filterKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = filterKey),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBatchCubit, CourseBatchState>(
      listener: (context, state) {
        if (state is CourseBatchError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Course',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      Text(
                        'Kelola batch dan jadwal pelaksanaan course',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showCreateForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Buat Batch'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Summary stat cards
            BlocBuilder<CourseBatchCubit, CourseBatchState>(
              builder: (context, state) {
                if (state is CourseBatchLoaded) {
                  final batches = state.batches;
                  final totalCount = batches.length;
                  final upcomingCount =
                      batches.where((b) => b.status == 'upcoming').length;
                  final ongoingCount =
                      batches.where((b) => b.status == 'ongoing').length;
                  final completedCount =
                      batches.where((b) => b.status == 'completed').length;

                  return Row(
                    children: [
                      _buildStatCard(
                        label: 'Semua',
                        count: totalCount,
                        filterKey: 'semua',
                        color: AppColors.primary,
                        surfaceColor: AppColors.primarySurface,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      _buildStatCard(
                        label: 'Akan Datang',
                        count: upcomingCount,
                        filterKey: 'upcoming',
                        color: AppColors.info,
                        surfaceColor: AppColors.infoSurface,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      _buildStatCard(
                        label: 'Berjalan',
                        count: ongoingCount,
                        filterKey: 'ongoing',
                        color: AppColors.success,
                        surfaceColor: AppColors.successSurface,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      _buildStatCard(
                        label: 'Selesai',
                        count: completedCount,
                        filterKey: 'completed',
                        color: AppColors.textSecondary,
                        surfaceColor: AppColors.surfaceVariant,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppDimensions.md),

            // Filter chips
            Wrap(
              spacing: AppDimensions.sm,
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _statusFilter == 'semua',
                  onSelected: (_) => setState(() => _statusFilter = 'semua'),
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                ),
                FilterChip(
                  label: const Text('Akan Datang'),
                  selected: _statusFilter == 'upcoming',
                  onSelected: (_) =>
                      setState(() => _statusFilter = 'upcoming'),
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                ),
                FilterChip(
                  label: const Text('Berjalan'),
                  selected: _statusFilter == 'ongoing',
                  onSelected: (_) =>
                      setState(() => _statusFilter = 'ongoing'),
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                ),
                FilterChip(
                  label: const Text('Selesai'),
                  selected: _statusFilter == 'completed',
                  onSelected: (_) =>
                      setState(() => _statusFilter = 'completed'),
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // Search field
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari batch...',
                  prefixIcon:
                      const Icon(Icons.search, size: AppDimensions.iconMd),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: AppDimensions.iconMd),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Table
            Expanded(
              child: BlocBuilder<CourseBatchCubit, CourseBatchState>(
                builder: (context, state) {
                  if (state is CourseBatchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CourseBatchError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: AppDimensions.md),
                          Text(state.message,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: AppDimensions.md),
                          FilledButton.icon(
                            onPressed: () =>
                                context.read<CourseBatchCubit>().loadBatches(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is CourseBatchLoaded) {
                    final batches = _filtered(state.batches);
                    if (batches.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_note_outlined,
                                  size: 48, color: AppColors.textHint),
                              const SizedBox(height: AppDimensions.md),
                              Text(
                                (_searchQuery.isNotEmpty ||
                                        _statusFilter != 'semua')
                                    ? 'Tidak ada batch yang cocok'
                                    : 'Belum ada batch course',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              if (_searchQuery.isEmpty &&
                                  _statusFilter == 'semua') ...[
                                const SizedBox(height: AppDimensions.sm),
                                TextButton.icon(
                                  onPressed: _showCreateForm,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Buat Batch Pertama'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DataTable2(
                        columnSpacing: AppDimensions.md,
                        horizontalMargin: AppDimensions.md,
                        headingRowHeight: AppDimensions.tableHeaderHeight,
                        dataRowHeight: AppDimensions.tableRowHeight,
                        headingRowColor:
                            WidgetStateProperty.all(AppColors.surfaceVariant),
                        columns: const [
                          DataColumn2(
                              label: Text('Nama Batch'), size: ColumnSize.L),
                          DataColumn2(
                              label: Text('Course'), size: ColumnSize.M),
                          DataColumn2(
                              label: Text('Mulai'),
                              size: ColumnSize.S,
                              fixedWidth: 120),
                          DataColumn2(
                              label: Text('Selesai'),
                              size: ColumnSize.S,
                              fixedWidth: 120),
                          DataColumn2(
                              label: Text('Kapasitas'),
                              size: ColumnSize.S,
                              fixedWidth: 100),
                          DataColumn2(
                              label: Text('Status'),
                              size: ColumnSize.S,
                              fixedWidth: 110),
                        ],
                        rows: batches
                            .map((b) => DataRow2(
                                  onSelectChanged: (_) =>
                                      context.go('/course-batches/${b.id}'),
                                  cells: [
                                    // Nama Batch: code + course type subtext
                                    DataCell(Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.code,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.textPrimary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                b.courseTypeName,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: AppColors.textHint,
                                        ),
                                      ],
                                    )),
                                    // Course: master course name
                                    DataCell(Text(
                                      b.masterCourseName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    DataCell(Text(
                                        DateFormatUtil.toDisplay(b.startDate),
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13))),
                                    DataCell(Text(
                                        DateFormatUtil.toDisplay(b.endDate),
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13))),
                                    DataCell(Text(
                                      '${b.maxParticipants} orang',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                    )),
                                    DataCell(_BatchStatusBadge(batch: b)),
                                  ],
                                ))
                            .toList(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchStatusBadge extends StatelessWidget {
  final CourseBatchEntity batch;
  const _BatchStatusBadge({required this.batch});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String label;
    final Color bg;
    final Color fg;

    if (!batch.isActive || batch.endDate.isBefore(now)) {
      label = 'Selesai';
      bg = AppColors.surfaceVariant;
      fg = AppColors.textSecondary;
    } else if (batch.startDate.isAfter(now)) {
      label = 'Akan Datang';
      bg = AppColors.infoSurface;
      fg = AppColors.info;
    } else {
      label = 'Berjalan';
      bg = AppColors.successSurface;
      fg = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}


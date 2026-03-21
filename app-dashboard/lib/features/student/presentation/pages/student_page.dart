import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/student_entity.dart';
import '../cubit/student_cubit.dart';
import '../cubit/student_state.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StudentCubit>()..loadStudents(),
      child: const _StudentView(),
    );
  }
}

class _StudentView extends StatefulWidget {
  const _StudentView();

  @override
  State<_StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<_StudentView> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _nameQuery = '';
  String _phoneQuery = '';
  String _emailQuery = '';
  // 'semua' | 'aktif' | 'tidak_aktif' | 'lulus'
  String _statusFilter = 'semua';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  List<StudentEntity> _filtered(List<StudentEntity> students) {
    return students.where((s) {
      final matchName = _nameQuery.isEmpty ||
          s.name.toLowerCase().contains(_nameQuery.toLowerCase());
      final matchPhone =
          _phoneQuery.isEmpty || s.phone.contains(_phoneQuery);
      final matchEmail = _emailQuery.isEmpty ||
          s.email.toLowerCase().contains(_emailQuery.toLowerCase());
      final matchStatus = _statusFilter == 'semua' ||
          s.status == _statusFilter;
      return matchName && matchPhone && matchEmail && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentCubit, StudentState>(
      listener: (context, state) {
        if (state is StudentError) {
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
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manajemen Siswa',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        'Data seluruh siswa terdaftar',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  onPressed: () =>
                      context.read<StudentCubit>().loadStudents(),
                  icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: AppDimensions.sm),
                FilledButton.icon(
                  onPressed: () => context.go('/students/new'),
                  icon: const Icon(Icons.add, size: AppDimensions.iconMd),
                  label: const Text('Tambah Siswa'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // ── Filter Row ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (v) => setState(() => _nameQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Nama',
                      prefixIcon: const Icon(Icons.search,
                          size: AppDimensions.iconMd),
                      suffixIcon: _nameQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: AppDimensions.iconMd),
                              onPressed: () {
                                _nameCtrl.clear();
                                setState(() => _nameQuery = '');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    onChanged: (v) => setState(() => _phoneQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Telp',
                      prefixIcon: const Icon(Icons.phone_outlined,
                          size: AppDimensions.iconMd),
                      suffixIcon: _phoneQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: AppDimensions.iconMd),
                              onPressed: () {
                                _phoneCtrl.clear();
                                setState(() => _phoneQuery = '');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    onChanged: (v) => setState(() => _emailQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined,
                          size: AppDimensions.iconMd),
                      suffixIcon: _emailQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: AppDimensions.iconMd),
                              onPressed: () {
                                _emailCtrl.clear();
                                setState(() => _emailQuery = '');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status Siswa',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'semua', child: Text('Semua')),
                      DropdownMenuItem(
                          value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(
                          value: 'tidak_aktif',
                          child: Text('Tidak Aktif')),
                      DropdownMenuItem(
                          value: 'lulus', child: Text('Lulus')),
                    ],
                    onChanged: (v) =>
                        setState(() => _statusFilter = v ?? 'semua'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Table ────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<StudentCubit, StudentState>(
                builder: (context, state) {
                  if (state is StudentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is StudentError) {
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
                                context.read<StudentCubit>().loadStudents(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is StudentLoaded) {
                    final students = _filtered(state.students);
                    if (students.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 48, color: AppColors.textHint),
                              const SizedBox(height: AppDimensions.md),
                              Text(
                                _nameQuery.isNotEmpty ||
                                        _phoneQuery.isNotEmpty ||
                                        _emailQuery.isNotEmpty ||
                                        _statusFilter != 'semua'
                                    ? 'Tidak ada siswa yang cocok'
                                    : 'Belum ada data siswa',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
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
                        headingRowColor: WidgetStateProperty.all(
                            AppColors.surfaceVariant),
                        columns: const [
                          DataColumn2(
                              label: Text('Nama'), size: ColumnSize.L),
                          DataColumn2(
                              label: Text('Email / Telp'),
                              size: ColumnSize.L),
                          DataColumn2(
                              label: Text('Batch Aktif'),
                              size: ColumnSize.S,
                              fixedWidth: 100),
                          DataColumn2(
                              label: Text('Selesai'),
                              size: ColumnSize.S,
                              fixedWidth: 100),
                          DataColumn2(
                              label: Text('Bergabung'),
                              size: ColumnSize.S,
                              fixedWidth: 130),
                          DataColumn2(
                              label: Text('Status'),
                              size: ColumnSize.S,
                              fixedWidth: 110),
                        ],
                        rows: students
                            .map((s) => DataRow2(
                                  onTap: () =>
                                      context.go('/students/${s.id}'),
                                  cells: [
                                    DataCell(
                                        _StudentNameCell(student: s)),
                                    DataCell(
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.email,
                                            style: const TextStyle(
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            s.phone.isEmpty ? '-' : s.phone,
                                            style: const TextStyle(
                                                color: AppColors.textHint,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text('${s.activeBatchCount}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13))),
                                    DataCell(Text(
                                        '${s.completedCourseCount}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13))),
                                    DataCell(Text(
                                        DateFormatUtil.toDisplay(s.joinedAt),
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13))),
                                    DataCell(_StatusBadge(status: s.status)),
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

// ── Student Name Cell ─────────────────────────────────────────────────────────

class _StudentNameCell extends StatefulWidget {
  final StudentEntity student;
  const _StudentNameCell({required this.student});

  @override
  State<_StudentNameCell> createState() => _StudentNameCellState();
}

class _StudentNameCellState extends State<_StudentNameCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final initials = widget.student.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              widget.student.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    _hovered ? AppColors.primaryLight : AppColors.primary,
                decoration:
                    _hovered ? TextDecoration.underline : null,
                decorationColor: AppColors.primaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _bg => switch (status) {
        'aktif' => AppColors.successSurface,
        'lulus' => AppColors.infoSurface,
        _ => AppColors.surfaceVariant,
      };

  Color get _fg => switch (status) {
        'aktif' => AppColors.success,
        'lulus' => AppColors.info,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (status) {
        'aktif' => 'Aktif',
        'lulus' => 'Lulus',
        _ => 'Tidak Aktif',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _fg,
        ),
      ),
    );
  }
}

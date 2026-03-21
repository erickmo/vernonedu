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
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    final cubit = context.read<StudentCubit>();
    showDialog(
      context: context,
      builder: (_) => _CreateStudentDialog(
        onCreate: ({required name, required email, phone}) =>
            cubit.createStudent(name: name, email: email, phone: phone ?? ''),
      ),
    );
  }

  List<StudentEntity> _filtered(List<StudentEntity> students) {
    if (_searchQuery.isEmpty) return students;
    final q = _searchQuery.toLowerCase();
    return students
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            s.phone.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentCubit, StudentState>(
      listener: (context, state) {
        if (state is StudentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manajemen Siswa',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        'Data seluruh siswa terdaftar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => context.read<StudentCubit>().loadStudents(),
                  icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: AppDimensions.sm),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, size: AppDimensions.iconMd),
                  label: const Text('Tambah Siswa'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari siswa...',
                  prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: AppDimensions.iconMd),
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
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: AppDimensions.md),
                          Text(state.message,
                              style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: AppDimensions.md),
                          FilledButton.icon(
                            onPressed: () => context.read<StudentCubit>().loadStudents(),
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
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ada siswa yang cocok'
                                    : 'Belum ada data siswa',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
                          DataColumn2(label: Text('Nama'), size: ColumnSize.L),
                          DataColumn2(label: Text('Email'), size: ColumnSize.L),
                          DataColumn2(label: Text('Telepon'), size: ColumnSize.M),
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
                              fixedWidth: 100),
                        ],
                        rows: students
                            .map((s) => DataRow2(
                                  onTap: () =>
                                      context.go('/students/${s.id}'),
                                  cells: [
                                    DataCell(_StudentNameCell(student: s)),
                                    DataCell(Text(s.email,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 13))),
                                    DataCell(Text(s.phone.isEmpty ? '-' : s.phone,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 13))),
                                    DataCell(Text('${s.activeBatchCount}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 13))),
                                    DataCell(Text('${s.completedCourseCount}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 13))),
                                    DataCell(Text(DateFormatUtil.toDisplay(s.joinedAt),
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 13))),
                                    DataCell(_StatusBadge(isActive: s.isActive)),
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
                color: _hovered ? AppColors.primaryLight : AppColors.primary,
                decoration: _hovered ? TextDecoration.underline : null,
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

// ── Create Student Dialog ─────────────────────────────────────────────────────

typedef CreateStudentCallback = Future<bool> Function({
  required String name,
  required String email,
  String? phone,
});

class _CreateStudentDialog extends StatefulWidget {
  final CreateStudentCallback onCreate;
  const _CreateStudentDialog({required this.onCreate});

  @override
  State<_CreateStudentDialog> createState() => _CreateStudentDialogState();
}

class _CreateStudentDialogState extends State<_CreateStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await widget.onCreate(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambah siswa. Coba lagi.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Siswa'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap *',
                  hintText: 'Masukkan nama siswa',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'siswa@email.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: '08xxxxxxxxxx',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

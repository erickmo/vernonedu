import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../course/presentation/cubit/course_cubit.dart';
import '../../../course/presentation/cubit/course_state.dart';
import '../../../course_type/presentation/cubit/course_type_cubit.dart';
import '../../../course_type/presentation/cubit/course_type_state.dart';
import '../cubit/course_version_cubit.dart';
import '../cubit/course_version_state.dart';

// ── Internal model untuk satu baris modul ────────────────────────────────────

class _ModuleRow {
  String title;
  int sessionCount;
  String description;

  _ModuleRow()
      : title = '',
        sessionCount = 1,
        description = '';
}

// ── Page Root ─────────────────────────────────────────────────────────────────

/// Halaman untuk mengajukan versi kurikulum baru.
/// Memilih Master Course → Tipe Kelas → mengisi daftar modul → submit.
class ProposeVersionPage extends StatelessWidget {
  const ProposeVersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CourseCubit>()..loadCourses()),
        BlocProvider(create: (_) => getIt<CourseTypeCubit>()),
        BlocProvider(create: (_) => getIt<CourseVersionCubit>()),
      ],
      child: const _ProposeVersionView(),
    );
  }
}

class _ProposeVersionView extends StatefulWidget {
  const _ProposeVersionView();

  @override
  State<_ProposeVersionView> createState() => _ProposeVersionViewState();
}

class _ProposeVersionViewState extends State<_ProposeVersionView> {
  String? _selectedCourseId;
  String? _selectedTypeId;
  String _changeType = 'minor';

  final _changelogCtrl = TextEditingController();
  final List<_ModuleRow> _modules = [];
  bool _submitting = false;

  @override
  void dispose() {
    _changelogCtrl.dispose();
    super.dispose();
  }

  void _onCourseChanged(String? courseId) {
    if (courseId == null) return;
    setState(() {
      _selectedCourseId = courseId;
      _selectedTypeId = null;
    });
    context.read<CourseTypeCubit>().loadTypes(courseId);
  }

  void _onTypeChanged(String? typeId) {
    setState(() => _selectedTypeId = typeId);
  }

  void _addModule() {
    setState(() => _modules.add(_ModuleRow()));
  }

  void _removeModule(int index) {
    setState(() => _modules.removeAt(index));
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final m = _modules.removeAt(index);
      _modules.insert(index - 1, m);
    });
  }

  void _moveDown(int index) {
    if (index >= _modules.length - 1) return;
    setState(() {
      final m = _modules.removeAt(index);
      _modules.insert(index + 1, m);
    });
  }

  Future<void> _submit() async {
    if (_selectedTypeId == null) {
      _showError('Pilih tipe kelas terlebih dahulu');
      return;
    }
    if (_modules.isEmpty) {
      _showError('Tambahkan minimal satu modul');
      return;
    }
    final emptyTitle = _modules.any((m) => m.title.trim().isEmpty);
    if (emptyTitle) {
      _showError('Semua modul harus memiliki judul');
      return;
    }

    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _submitting = true);

    final modulesData = _modules
        .asMap()
        .entries
        .map((e) => {
              'title': e.value.title.trim(),
              'sequence': e.key + 1,
              'session_count': e.value.sessionCount,
              'description': e.value.description.trim(),
            })
        .toList();

    final data = {
      'changelog': _changelogCtrl.text.trim(),
      'change_type': _changeType,
      'modules': modulesData,
    };

    final cubit = context.read<CourseVersionCubit>();
    final success = await cubit.createVersion(_selectedTypeId!, data);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Versi kurikulum berhasil diajukan'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/curriculum');
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Pengajuan'),
            content: Text(
              'Ajukan versi kurikulum baru dengan ${_modules.length} modul?\n\n'
              'Versi ini akan masuk ke tahap review sebelum disetujui.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ajukan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseVersionCubit, CourseVersionState>(
      listener: (context, state) {
        if (state is CourseVersionError) {
          _showError(state.message);
          if (_submitting) setState(() => _submitting = false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppDimensions.lg),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSelectionSection(),
                    const SizedBox(height: AppDimensions.lg),
                    _buildVersionInfoSection(),
                    const SizedBox(height: AppDimensions.lg),
                    _buildModulesSection(),
                    const SizedBox(height: AppDimensions.xl),
                    _buildSubmitButton(),
                    const SizedBox(height: AppDimensions.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/curriculum'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/curriculum'),
                  child: const Text(
                    'Kurikulum',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right,
                      size: 14, color: AppColors.textHint),
                ),
                const Text(
                  'Usulkan Versi Baru',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            Text(
              'Usulkan Versi Kurikulum Baru',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Course',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.md),
          BlocBuilder<CourseCubit, CourseState>(
            builder: (context, state) {
              if (state is CourseLoading) {
                return const SizedBox(
                  height: 40,
                  child:
                      Center(child: LinearProgressIndicator()),
                );
              }
              if (state is CourseLoaded) {
                return DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  decoration: InputDecoration(
                    labelText: 'Master Course',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md, vertical: 12),
                  ),
                  hint: const Text('Pilih course...'),
                  items: state.courses
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.courseName} (${c.courseCode})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _onCourseChanged,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          if (_selectedCourseId != null) ...[
            const SizedBox(height: AppDimensions.md),
            const Text(
              'Pilih Tipe Kelas',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppDimensions.sm),
            BlocBuilder<CourseTypeCubit, CourseTypeState>(
              builder: (context, state) {
                if (state is CourseTypeLoading) {
                  return const SizedBox(
                    height: 40,
                    child: Center(child: LinearProgressIndicator()),
                  );
                }
                if (state is CourseTypeLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedTypeId,
                    decoration: InputDecoration(
                      labelText: 'Tipe Kelas',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.md, vertical: 12),
                    ),
                    hint: const Text('Pilih tipe kelas...'),
                    items: state.types
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.typeLabel),
                            ))
                        .toList(),
                    onChanged: _onTypeChanged,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Versi',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.md),
          DropdownButtonFormField<String>(
            value: _changeType,
            decoration: InputDecoration(
              labelText: 'Jenis Perubahan',
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'major', child: Text('Major — Perubahan besar')),
              DropdownMenuItem(
                  value: 'minor', child: Text('Minor — Penambahan fitur')),
              DropdownMenuItem(
                  value: 'patch', child: Text('Patch — Perbaikan kecil')),
            ],
            onChanged: (v) => setState(() => _changeType = v ?? 'minor'),
          ),
          const SizedBox(height: AppDimensions.md),
          TextField(
            controller: _changelogCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan Perubahan (Changelog)',
              hintText: 'Deskripsikan perubahan yang diusulkan...',
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd)),
              contentPadding: const EdgeInsets.all(AppDimensions.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
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
              const Text(
                'Modul Kurikulum',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _addModule,
                icon: const Icon(Icons.add, size: AppDimensions.iconMd),
                label: const Text('Tambah Modul'),
              ),
            ],
          ),
          if (_modules.isEmpty) ...[
            const SizedBox(height: AppDimensions.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Column(
                children: [
                  Icon(Icons.list_alt_outlined,
                      size: 40, color: AppColors.textHint),
                  SizedBox(height: AppDimensions.sm),
                  Text(
                    'Belum ada modul. Klik "Tambah Modul" untuk mulai.',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppDimensions.md),
            // Module table header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: AppDimensions.sm),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 32, child: Text('No', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                  SizedBox(width: AppDimensions.sm),
                  Expanded(flex: 3, child: Text('Judul Modul', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                  SizedBox(width: AppDimensions.sm),
                  SizedBox(width: 100, child: Text('Jumlah Sesi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                  SizedBox(width: AppDimensions.sm),
                  SizedBox(width: 100, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                ],
              ),
            ),
            ...List.generate(_modules.length, (i) => _buildModuleRow(i)),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleRow(int i) {
    final m = _modules[i];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: m.title,
              decoration: InputDecoration(
                hintText: 'Judul modul...',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm, vertical: 8),
              ),
              onChanged: (v) => m.title = v,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: '${m.sessionCount}',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm, vertical: 8),
              ),
              onChanged: (v) =>
                  m.sessionCount = int.tryParse(v) ?? 1,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  onPressed: i > 0 ? () => _moveUp(i) : null,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  tooltip: 'Pindah ke atas',
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed:
                      i < _modules.length - 1 ? () => _moveDown(i) : null,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  tooltip: 'Pindah ke bawah',
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: () => _removeModule(i),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  tooltip: 'Hapus modul',
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => context.go('/curriculum'),
          child: const Text('Batal'),
        ),
        const SizedBox(width: AppDimensions.md),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_outlined, size: AppDimensions.iconMd),
          label: Text(_submitting ? 'Mengajukan...' : 'Ajukan Versi Baru'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            fixedSize: const Size.fromHeight(AppDimensions.buttonHeightLg),
          ),
        ),
      ],
    );
  }
}

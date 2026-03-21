import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
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

  void _showCreateForm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseBatchCubit>(),
        child: const _CreateBatchDialog(),
      ),
    );
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

// ─── Create Batch Dialog ────────────────────────────────────────────────────

class _CreateBatchDialog extends StatefulWidget {
  const _CreateBatchDialog();

  @override
  State<_CreateBatchDialog> createState() => _CreateBatchDialogState();
}

class _CreateBatchDialogState extends State<_CreateBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(text: '30');
  final _sessionsCtrl = TextEditingController(text: '8');
  final _facilitatorCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  String? _selectedCourseId;
  Map<String, dynamic>? _selectedCourse;
  Map<String, dynamic>? _selectedDept;

  late final Future<_BatchFormData> _formDataFuture;

  @override
  void initState() {
    super.initState();
    _formDataFuture = _loadFormData();
  }

  Future<_BatchFormData> _loadFormData() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final results = await Future.wait([
        dio.get('/courses', queryParameters: {'limit': 100}),
        dio.get('/departments', queryParameters: {'limit': 100}),
      ]);
      final courses = ((results[0].data as Map)['data'] as List)
          .cast<Map<String, dynamic>>();
      final depts = ((results[1].data as Map)['data'] as List)
          .cast<Map<String, dynamic>>();
      return _BatchFormData(courses, depts);
    } catch (_) {
      return const _BatchFormData([], []);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxCtrl.dispose();
    _sessionsCtrl.dispose();
    _facilitatorCtrl.dispose();
    super.dispose();
  }

  void _onCourseSelected(String? courseId, _BatchFormData formData) {
    setState(() {
      _selectedCourseId = courseId;
      _selectedCourse =
          formData.courses.where((c) => c['id'] == courseId).firstOrNull;
      if (_selectedCourse != null) {
        final deptId = _selectedCourse!['department_id'] as String?;
        _selectedDept =
            formData.departments.where((d) => d['id'] == deptId).firstOrNull;
      } else {
        _selectedDept = null;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ??
            (_startDate ?? DateTime.now()).add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tanggal mulai dan selesai wajib diisi')),
      );
      return;
    }
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course wajib dipilih')),
      );
      return;
    }
    setState(() => _isLoading = true);

    final data = {
      'course_id': _selectedCourseId,
      'name': _nameCtrl.text.trim(),
      'start_date': DateFormatUtil.toApi(_startDate!),
      'end_date': DateFormatUtil.toApi(_endDate!),
      'max_participants': int.tryParse(_maxCtrl.text.trim()) ?? 30,
      'is_active': _isActive,
    };

    final cubit = context.read<CourseBatchCubit>();
    final success = await cubit.createBatch(data);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch berhasil dibuat'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 600,
        child: FutureBuilder<_BatchFormData>(
          future: _formDataFuture,
          builder: (context, snapshot) {
            final formData = snapshot.data ?? const _BatchFormData([], []);
            final isLoadingData =
                snapshot.connectionState == ConnectionState.waiting;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.radiusLg)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        child: const Icon(Icons.event_note_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buat Batch Baru',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            'Isi detail batch pelaksanaan course',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Form body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Pilih Course
                          _SectionLabel(label: 'Informasi Course'),
                          const SizedBox(height: AppDimensions.sm),
                          if (isLoadingData)
                            const LinearProgressIndicator()
                          else
                            DropdownButtonFormField<String>(
                              value: _selectedCourseId,
                              decoration: const InputDecoration(
                                labelText: 'Course',
                                prefixIcon: Icon(Icons.menu_book_outlined),
                              ),
                              hint:
                                  const Text('Pilih course yang akan dibatch'),
                              items: formData.courses
                                  .map((c) => DropdownMenuItem<String>(
                                        value: c['id'] as String,
                                        child: Text(c['name'] as String),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  _onCourseSelected(v, formData),
                              validator: (v) =>
                                  v == null ? 'Course wajib dipilih' : null,
                            ),
                          // Course info card
                          if (_selectedCourse != null) ...[
                            const SizedBox(height: AppDimensions.sm),
                            _CourseInfoCard(
                              course: _selectedCourse!,
                              department: _selectedDept,
                            ),
                          ],
                          const SizedBox(height: AppDimensions.lg),

                          // Section: Detail Batch
                          _SectionLabel(label: 'Detail Batch'),
                          const SizedBox(height: AppDimensions.sm),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nama Batch',
                              hintText: 'Contoh: Batch 3 - Maret 2026',
                              prefixIcon: Icon(Icons.label_outline),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nama batch wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(
                                  label: 'Tanggal Mulai',
                                  date: _startDate,
                                  onTap: () => _pickDate(isStart: true),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.md),
                              Expanded(
                                child: _DateField(
                                  label: 'Tanggal Selesai',
                                  date: _endDate,
                                  onTap: () => _pickDate(isStart: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.md),

                          // Section: Kapasitas & Sesi
                          _SectionLabel(label: 'Kapasitas & Sesi'),
                          const SizedBox(height: AppDimensions.sm),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _maxCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Kapasitas Maks.',
                                    suffixText: 'peserta',
                                    prefixIcon: Icon(Icons.people_outline),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (int.tryParse(v) == null) {
                                      return 'Angka tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppDimensions.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _sessionsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Jumlah Sesi',
                                    suffixText: 'sesi',
                                    prefixIcon: Icon(Icons.layers_outlined),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (int.tryParse(v) == null) {
                                      return 'Angka tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.md),

                          // Section: Fasilitator
                          _SectionLabel(label: 'Fasilitator'),
                          const SizedBox(height: AppDimensions.sm),
                          TextFormField(
                            controller: _facilitatorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nama Fasilitator',
                              hintText: 'Nama fasilitator yang mengajar',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Aktifkan Batch'),
                            subtitle: Text(
                              _isActive
                                  ? 'Batch langsung aktif saat dibuat'
                                  : 'Batch dalam mode draft',
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Buat Batch'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BatchFormData {
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> departments;
  const _BatchFormData(this.courses, this.departments);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _CourseInfoCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final Map<String, dynamic>? department;
  const _CourseInfoCard({required this.course, this.department});

  @override
  Widget build(BuildContext context) {
    final ownerId = course['owner_id'] as String? ?? '';
    final ownerShort = ownerId.length > 8 ? ownerId.substring(0, 8) : ownerId;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Informasi Course',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          _InfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Course',
            value: course['name'] as String? ?? '-',
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.corporate_fare_outlined,
            label: 'Departemen',
            value: department?['name'] as String? ?? 'Tidak ada departemen',
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Course Owner',
            value: ownerId.isEmpty ? 'Belum ditentukan' : 'ID: ...$ownerShort',
          ),
          if ((course['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'Deskripsi',
              value: course['description'] as String,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: AppDimensions.iconMd),
        ),
        child: Text(
          date != null ? DateFormatUtil.toDisplay(date!) : 'Pilih tanggal',
          style: TextStyle(
            color: date != null ? AppColors.textPrimary : AppColors.textHint,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

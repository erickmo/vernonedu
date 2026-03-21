import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/enrollment_batch_summary_entity.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../cubit/enrollment_cubit.dart';
import '../cubit/enrollment_state.dart';

class EnrollmentPage extends StatelessWidget {
  const EnrollmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EnrollmentCubit>()..loadSummary(),
      child: const _EnrollmentView(),
    );
  }
}

class _EnrollmentView extends StatefulWidget {
  const _EnrollmentView();

  @override
  State<_EnrollmentView> createState() => _EnrollmentViewState();
}

class _EnrollmentViewState extends State<_EnrollmentView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Tab 1 filters
  String _courseFilter = '';
  String _statusFilter = 'semua';
  String _deptFilter = 'semua';

  // Tab 2 filter
  String _logStatusFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final cubit = context.read<EnrollmentCubit>();
    if (_tabController.index == 0) {
      cubit.loadSummary();
    } else {
      cubit.loadEnrollments();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Status helpers ---
  String _batchStatusLabel(String s) {
    switch (s) {
      case 'upcoming':
        return 'Akan Datang';
      case 'ongoing':
        return 'Sedang Berjalan';
      case 'completed':
        return 'Selesai';
      default:
        return s;
    }
  }

  Color _batchStatusColor(String s) {
    switch (s) {
      case 'upcoming':
        return AppColors.info;
      case 'ongoing':
        return AppColors.success;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _batchStatusBg(String s) {
    switch (s) {
      case 'upcoming':
        return AppColors.infoSurface;
      case 'ongoing':
        return AppColors.successSurface;
      case 'completed':
        return AppColors.surfaceVariant;
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color _enrollStatusColor(String s) {
    switch (s) {
      case 'active':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'dropped':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _enrollStatusBg(String s) {
    switch (s) {
      case 'active':
        return AppColors.successSurface;
      case 'completed':
        return AppColors.primarySurface;
      case 'dropped':
        return AppColors.errorSurface;
      default:
        return AppColors.surfaceVariant;
    }
  }

  String _enrollStatusLabel(String s) {
    switch (s) {
      case 'active':
        return 'Aktif';
      case 'completed':
        return 'Selesai';
      case 'dropped':
        return 'Keluar';
      default:
        return s;
    }
  }

  Color _paymentColor(String s) {
    switch (s) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _paymentLabel(String s) {
    switch (s) {
      case 'paid':
        return 'Lunas';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Gagal';
      default:
        return s;
    }
  }

  // --- Filter helpers ---
  List<EnrollmentBatchSummaryEntity> _filteredSummaries(
      List<EnrollmentBatchSummaryEntity> items) {
    final filtered = items.where((e) {
      final matchCourse = _courseFilter.isEmpty ||
          e.courseName.toLowerCase().contains(_courseFilter.toLowerCase());
      final matchStatus =
          _statusFilter == 'semua' || e.batchStatus == _statusFilter;
      final matchDept = _deptFilter == 'semua' ||
          e.departmentId == _deptFilter ||
          e.departmentName == _deptFilter;
      return matchCourse && matchStatus && matchDept;
    }).toList();

    // Sort by closest start date ascending
    filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
    return filtered;
  }

  List<EnrollmentEntity> _filteredLog(List<EnrollmentEntity> items) {
    if (_logStatusFilter == 'semua') return items;
    return items.where((e) => e.status == _logStatusFilter).toList();
  }

  double _fillRatio(EnrollmentBatchSummaryEntity e) {
    if (e.maxParticipants == 0) return 0;
    return (e.enrollmentCount / e.maxParticipants).clamp(0.0, 1.0);
  }

  void _showEnrollDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<EnrollmentCubit>(),
        child: const _EnrollStudentDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnrollmentCubit, EnrollmentState>(
      listener: (context, state) {
        if (state is EnrollmentError) {
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enrollment Siswa',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        'Kelola pendaftaran siswa ke batch course',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<EnrollmentCubit, EnrollmentState>(
                  builder: (context, state) => IconButton.outlined(
                    onPressed: () {
                      if (_tabController.index == 0) {
                        context.read<EnrollmentCubit>().loadSummary();
                      } else {
                        context.read<EnrollmentCubit>().loadEnrollments();
                      }
                    },
                    icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
                    tooltip: 'Refresh',
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                FilledButton.icon(
                  onPressed: () => _showEnrollDialog(context),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Daftarkan Siswa'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // Tab section wrapped in card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // TabBar inside card
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusLg),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Berdasarkan Batch'),
                          Tab(text: 'Log Enrollment'),
                        ],
                      ),
                    ),

                    // TabBarView inside card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _BatchTab(
                              courseFilter: _courseFilter,
                              statusFilter: _statusFilter,
                              deptFilter: _deptFilter,
                              onCourseFilterChanged: (v) =>
                                  setState(() => _courseFilter = v),
                              onStatusFilterChanged: (v) =>
                                  setState(() => _statusFilter = v),
                              onDeptFilterChanged: (v) =>
                                  setState(() => _deptFilter = v),
                              filteredSummaries: _filteredSummaries,
                              batchStatusLabel: _batchStatusLabel,
                              batchStatusColor: _batchStatusColor,
                              batchStatusBg: _batchStatusBg,
                              fillRatio: _fillRatio,
                            ),
                            _LogTab(
                              statusFilter: _logStatusFilter,
                              onStatusFilterChanged: (v) =>
                                  setState(() => _logStatusFilter = v),
                              filteredLog: _filteredLog,
                              enrollStatusLabel: _enrollStatusLabel,
                              enrollStatusColor: _enrollStatusColor,
                              enrollStatusBg: _enrollStatusBg,
                              paymentLabel: _paymentLabel,
                              paymentColor: _paymentColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Enroll Student Dialog ────────────────────────────────────────────────────

class _EnrollStudentDialog extends StatefulWidget {
  const _EnrollStudentDialog();

  @override
  State<_EnrollStudentDialog> createState() => _EnrollStudentDialogState();
}

class _EnrollStudentDialogState extends State<_EnrollStudentDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _batches = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  String? _selectedStudentId;
  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final results = await Future.wait([
        dio.get('/students', queryParameters: {'limit': 200}),
        dio.get('/course-batches', queryParameters: {'limit': 200}),
      ]);

      List<Map<String, dynamic>> parseList(Response res) {
        final raw = res.data;
        final list = (raw is Map && raw['data'] != null)
            ? raw['data'] as List
            : raw is List
                ? raw
                : <dynamic>[];
        return list.cast<Map<String, dynamic>>();
      }

      if (mounted) {
        setState(() {
          _students = parseList(results[0]);
          _batches = parseList(results[1]);
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Map<String, dynamic>? get _selectedStudent =>
      _selectedStudentId == null
          ? null
          : _students.where((s) => s['id'] == _selectedStudentId).firstOrNull;

  Map<String, dynamic>? get _selectedBatch =>
      _selectedBatchId == null
          ? null
          : _batches.where((b) => b['id'] == _selectedBatchId).firstOrNull;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedBatchId == null) return;

    setState(() => _isSubmitting = true);

    final cubit = context.read<EnrollmentCubit>();
    final success = await cubit.enrollStudent({
      'student_id': _selectedStudentId,
      'course_batch_id': _selectedBatchId,
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Siswa berhasil didaftarkan'),
            backgroundColor: AppColors.success,
          ),
        );
        cubit.loadSummary();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLg),
                ),
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
                    child: const Icon(Icons.person_add_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftarkan Siswa',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        'Pilih siswa dan batch tujuan',
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
                      if (_isLoadingData)
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: AppDimensions.md),
                          child: LinearProgressIndicator(),
                        )
                      else ...[
                        // Pilih Siswa
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStudentId,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Siswa',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          hint: const Text('Cari dan pilih siswa'),
                          isExpanded: true,
                          items: _students
                              .map((s) => DropdownMenuItem<String>(
                                    value: s['id'] as String? ?? '',
                                    child: Text(
                                      '${s['name'] ?? ''} (${s['student_code'] ?? ''})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedStudentId = v),
                          validator: (v) =>
                              v == null ? 'Siswa wajib dipilih' : null,
                        ),
                        const SizedBox(height: AppDimensions.md),

                        // Pilih Batch
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBatchId,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Batch',
                            prefixIcon: Icon(Icons.event_note_outlined),
                          ),
                          hint: const Text('Cari dan pilih batch'),
                          isExpanded: true,
                          items: _batches
                              .map((b) => DropdownMenuItem<String>(
                                    value: b['id'] as String? ?? '',
                                    child: Text(
                                      '${b['code'] ?? ''} - ${b['master_course_name'] ?? ''} (${b['status'] ?? ''})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedBatchId = v),
                          validator: (v) =>
                              v == null ? 'Batch wajib dipilih' : null,
                        ),
                        const SizedBox(height: AppDimensions.md),

                        // Selected info card
                        if (_selectedStudent != null &&
                            _selectedBatch != null) ...[
                          _EnrollInfoCard(
                            student: _selectedStudent!,
                            batch: _selectedBatch!,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Daftarkan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Enroll Info Card ─────────────────────────────────────────────────────────

class _EnrollInfoCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> batch;

  const _EnrollInfoCard({required this.student, required this.batch});

  @override
  Widget build(BuildContext context) {
    final maxParticipants = (batch['max_participants'] as num?)?.toInt() ?? 0;
    final totalEnrolled = (batch['total_enrolled'] as num?)?.toInt() ?? 0;
    final remaining = (maxParticipants - totalEnrolled).clamp(0, maxParticipants);

    String formatDate(dynamic raw) {
      if (raw == null) return '—';
      try {
        return DateFormatUtil.toDisplay(DateTime.parse(raw as String));
      } catch (_) {
        return raw.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Ringkasan Pendaftaran',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Siswa',
            value:
                '${student['name'] ?? '—'} · ${student['student_code'] ?? '—'}',
          ),
          const SizedBox(height: AppDimensions.xs),
          _InfoRow(
            icon: Icons.event_note_outlined,
            label: 'Batch',
            value: batch['code'] as String? ?? '—',
          ),
          const SizedBox(height: AppDimensions.xs),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Jadwal',
            value:
                '${formatDate(batch['start_date'])} – ${formatDate(batch['end_date'])}',
          ),
          const SizedBox(height: AppDimensions.xs),
          _InfoRow(
            icon: Icons.people_outline,
            label: 'Sisa Kapasitas',
            value: maxParticipants == 0
                ? '—'
                : '$remaining dari $maxParticipants slot tersedia',
            valueColor: remaining == 0 ? AppColors.error : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Berdasarkan Batch ─────────────────────────────────────────────────

class _BatchTab extends StatelessWidget {
  final String courseFilter;
  final String statusFilter;
  final String deptFilter;
  final ValueChanged<String> onCourseFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final ValueChanged<String> onDeptFilterChanged;
  final List<EnrollmentBatchSummaryEntity> Function(
      List<EnrollmentBatchSummaryEntity>) filteredSummaries;
  final String Function(String) batchStatusLabel;
  final Color Function(String) batchStatusColor;
  final Color Function(String) batchStatusBg;
  final double Function(EnrollmentBatchSummaryEntity) fillRatio;

  const _BatchTab({
    required this.courseFilter,
    required this.statusFilter,
    required this.deptFilter,
    required this.onCourseFilterChanged,
    required this.onStatusFilterChanged,
    required this.onDeptFilterChanged,
    required this.filteredSummaries,
    required this.batchStatusLabel,
    required this.batchStatusColor,
    required this.batchStatusBg,
    required this.fillRatio,
  });

  static const _statusOptions = ['semua', 'upcoming', 'ongoing', 'completed'];
  static const _statusLabels = {
    'semua': 'Semua Status',
    'upcoming': 'Akan Datang',
    'ongoing': 'Sedang Berjalan',
    'completed': 'Selesai',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnrollmentCubit, EnrollmentState>(
      builder: (context, state) {
        if (state is EnrollmentSummaryLoading || state is EnrollmentLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is EnrollmentError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<EnrollmentCubit>().loadSummary(),
          );
        }
        if (state is EnrollmentSummaryLoaded) {
          final items = filteredSummaries(state.summaries);
          final depts = _uniqueDepts(state.summaries);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterRow(
                courseFilter: courseFilter,
                statusFilter: statusFilter,
                deptFilter: deptFilter,
                depts: depts,
                statusOptions: _statusOptions,
                statusLabels: _statusLabels,
                onCourseChanged: onCourseFilterChanged,
                onStatusChanged: onStatusFilterChanged,
                onDeptChanged: onDeptFilterChanged,
              ),
              const SizedBox(height: AppDimensions.md),
              Expanded(
                child: items.isEmpty
                    ? const _EmptyView(
                        message: 'Tidak ada batch yang sesuai filter')
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppDimensions.md,
                          mainAxisSpacing: AppDimensions.md,
                          childAspectRatio: 1.55,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _BatchCard(
                          item: items[i],
                          batchStatusLabel: batchStatusLabel,
                          batchStatusColor: batchStatusColor,
                          batchStatusBg: batchStatusBg,
                          fillRatio: fillRatio,
                        ),
                      ),
              ),
            ],
          );
        }
        // State is EnrollmentLoaded (user was on Log tab) → reload summary
        if (state is EnrollmentLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<EnrollmentCubit>().loadSummary();
          });
          return const Center(child: CircularProgressIndicator());
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<Map<String, String>> _uniqueDepts(
      List<EnrollmentBatchSummaryEntity> items) {
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final e in items) {
      if (e.departmentId.isNotEmpty && seen.add(e.departmentId)) {
        result.add({'id': e.departmentId, 'name': e.departmentName});
      }
    }
    return result;
  }
}

class _FilterRow extends StatelessWidget {
  final String courseFilter;
  final String statusFilter;
  final String deptFilter;
  final List<Map<String, String>> depts;
  final List<String> statusOptions;
  final Map<String, String> statusLabels;
  final ValueChanged<String> onCourseChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onDeptChanged;

  const _FilterRow({
    required this.courseFilter,
    required this.statusFilter,
    required this.deptFilter,
    required this.depts,
    required this.statusOptions,
    required this.statusLabels,
    required this.onCourseChanged,
    required this.onStatusChanged,
    required this.onDeptChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 36,
          child: TextField(
            onChanged: onCourseChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama course...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search,
                  size: AppDimensions.iconSm, color: AppColors.textHint),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        ...statusOptions.map((s) => FilterChip(
              label: Text(statusLabels[s] ?? s,
                  style: const TextStyle(fontSize: 12)),
              selected: statusFilter == s,
              onSelected: (_) => onStatusChanged(s),
              selectedColor: AppColors.primarySurface,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: statusFilter == s
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: statusFilter == s
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            )),
        if (depts.isNotEmpty)
          DropdownButton<String>(
            value: deptFilter,
            underline: const SizedBox.shrink(),
            hint: const Text('Departemen', style: TextStyle(fontSize: 13)),
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary),
            items: [
              const DropdownMenuItem(
                  value: 'semua',
                  child: Text('Semua Departemen',
                      style: TextStyle(fontSize: 13))),
              ...depts.map((d) => DropdownMenuItem(
                  value: d['id'],
                  child: Text(d['name'] ?? '',
                      style: const TextStyle(fontSize: 13)))),
            ],
            onChanged: (v) {
              if (v != null) onDeptChanged(v);
            },
          ),
      ],
    );
  }
}

// ─── Compact Batch Card (1/3 page width) ──────────────────────────────────────

class _BatchCard extends StatelessWidget {
  final EnrollmentBatchSummaryEntity item;
  final String Function(String) batchStatusLabel;
  final Color Function(String) batchStatusColor;
  final Color Function(String) batchStatusBg;
  final double Function(EnrollmentBatchSummaryEntity) fillRatio;

  const _BatchCard({
    required this.item,
    required this.batchStatusLabel,
    required this.batchStatusColor,
    required this.batchStatusBg,
    required this.fillRatio,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.batchStatus;
    final ratio = fillRatio(item);
    final fillColor = ratio >= 1.0 ? AppColors.error : AppColors.primary;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.go('/course-batches/${item.batchId}'),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Course name + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.courseName.isNotEmpty
                        ? item.courseName
                        : 'Course tidak ditemukan',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.xs),
                _Badge(
                  label: batchStatusLabel(status),
                  color: batchStatusColor(status),
                  bgColor: batchStatusBg(status),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),

            // Batch name
            Text(
              item.batchName,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.xs),

            // Department
            if (item.departmentName.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.apartment,
                      size: 11, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      item.departmentName,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textHint, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            const Spacer(),

            // Date range
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 11, color: AppColors.textHint),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${DateFormatUtil.toDisplay(item.startDate)} – ${DateFormatUtil.toDisplay(item.endDate)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),

            // Progress bar + count
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircle),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.xs),
                Text(
                  '${item.enrollmentCount}/${item.maxParticipants}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fillColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Log Enrollment ────────────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final List<EnrollmentEntity> Function(List<EnrollmentEntity>) filteredLog;
  final String Function(String) enrollStatusLabel;
  final Color Function(String) enrollStatusColor;
  final Color Function(String) enrollStatusBg;
  final String Function(String) paymentLabel;
  final Color Function(String) paymentColor;

  const _LogTab({
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.filteredLog,
    required this.enrollStatusLabel,
    required this.enrollStatusColor,
    required this.enrollStatusBg,
    required this.paymentLabel,
    required this.paymentColor,
  });

  static const _statuses = ['semua', 'active', 'completed', 'dropped'];
  static const _statusLabels = {
    'semua': 'Semua',
    'active': 'Aktif',
    'completed': 'Selesai',
    'dropped': 'Keluar',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnrollmentCubit, EnrollmentState>(
      builder: (context, state) {
        if (state is EnrollmentLoading || state is EnrollmentSummaryLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is EnrollmentError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<EnrollmentCubit>().loadEnrollments(),
          );
        }
        if (state is EnrollmentLoaded) {
          final items = filteredLog(state.enrollments);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses
                      .map((s) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppDimensions.sm),
                            child: FilterChip(
                              label: Text(_statusLabels[s] ?? s,
                                  style: const TextStyle(fontSize: 12)),
                              selected: statusFilter == s,
                              onSelected: (_) => onStatusFilterChanged(s),
                              selectedColor: AppColors.primarySurface,
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: statusFilter == s
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: statusFilter == s
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              Expanded(
                child: items.isEmpty
                    ? _EmptyView(
                        message: statusFilter != 'semua'
                            ? 'Tidak ada enrollment dengan status ini'
                            : 'Belum ada enrollment',
                      )
                    : Container(
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
                              label: Text('Waktu Enrollment'),
                              size: ColumnSize.S,
                              fixedWidth: 140,
                            ),
                            DataColumn2(
                              label: Text('Nama Siswa'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('No. HP'),
                              size: ColumnSize.S,
                              fixedWidth: 130,
                            ),
                            DataColumn2(
                              label: Text('Course'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Course Batch'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Status'),
                              size: ColumnSize.S,
                              fixedWidth: 90,
                            ),
                            DataColumn2(
                              label: Text('Payment Via'),
                              size: ColumnSize.S,
                              fixedWidth: 100,
                            ),
                          ],
                          rows: items
                              .map((e) => DataRow2(cells: [
                                    // Waktu Enrollment
                                    DataCell(Text(
                                      DateFormatUtil.toDisplay(e.enrolledAt),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    )),
                                    // Nama Siswa (link)
                                    DataCell(
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () => context
                                              .go('/students/${e.studentId}'),
                                          child: Text(
                                            e.studentName.isNotEmpty
                                                ? e.studentName
                                                : e.studentId.length > 8
                                                    ? e.studentId.substring(
                                                        0, 8)
                                                    : e.studentId,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // No. HP
                                    DataCell(Text(
                                      e.studentPhone.isNotEmpty
                                          ? e.studentPhone
                                          : '—',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                    )),
                                    // Course
                                    DataCell(Text(
                                      e.courseName.isNotEmpty
                                          ? e.courseName
                                          : '—',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    // Course Batch (link)
                                    DataCell(
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () => context.go(
                                              '/course-batches/${e.courseBatchId}'),
                                          child: Text(
                                            e.batchName.isNotEmpty
                                                ? e.batchName
                                                : e.courseBatchId.length > 8
                                                    ? e.courseBatchId
                                                        .substring(0, 8)
                                                    : e.courseBatchId,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.primary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Status
                                    DataCell(_Badge(
                                      label: enrollStatusLabel(e.status),
                                      color: enrollStatusColor(e.status),
                                      bgColor: enrollStatusBg(e.status),
                                    )),
                                    // Payment Via
                                    DataCell(_Badge(
                                      label: paymentLabel(e.paymentStatus),
                                      color: paymentColor(e.paymentStatus),
                                      bgColor: paymentColor(e.paymentStatus)
                                          .withValues(alpha: 0.12),
                                    )),
                                  ]))
                              .toList(),
                        ),
                      ),
              ),
            ],
          );
        }
        // State is EnrollmentSummaryLoaded (user switched to Log tab) → load enrollments
        if (state is EnrollmentSummaryLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<EnrollmentCubit>().loadEnrollments();
          });
          return const Center(child: CircularProgressIndicator());
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge(
      {required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.how_to_reg_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

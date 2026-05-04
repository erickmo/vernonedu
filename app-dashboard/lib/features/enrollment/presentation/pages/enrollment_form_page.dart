import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../cubit/enrollment_cubit.dart';

class EnrollmentFormPage extends StatelessWidget {
  const EnrollmentFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EnrollmentCubit>(),
      child: const _EnrollmentFormView(),
    );
  }
}

class _EnrollmentFormView extends StatefulWidget {
  const _EnrollmentFormView();

  @override
  State<_EnrollmentFormView> createState() => _EnrollmentFormViewState();
}

class _EnrollmentFormViewState extends State<_EnrollmentFormView> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStudentId;
  String? _selectedBatchId;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _batches = [];
  bool _loadingDropdowns = true;
  bool _isSubmitting = false;
  String? _dropdownError;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final results = await Future.wait([
        dio.get('/students?limit=200'),
        dio.get('/course-batches?limit=200'),
      ]);

      final studentList = _parseList(results[0].data);
      final batchList = _parseList(results[1].data);

      if (mounted) {
        setState(() {
          _students = studentList;
          _batches = batchList;
          _loadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dropdownError = 'Gagal memuat data: $e';
          _loadingDropdowns = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      return (raw['data'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'studentId': _selectedStudentId,
      'batchId': _selectedBatchId,
    };

    final success =
        await context.read<EnrollmentCubit>().enrollStudent(data);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrollment berhasil dibuat'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat enrollment'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDropdowns) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dropdownError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppDimensions.md),
            Text(_dropdownError!,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.md),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loadingDropdowns = true;
                  _dropdownError = null;
                });
                _loadDropdownData();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar ──────────────────────────────────────────────
          Row(
            children: [
              IconButton.outlined(
                onPressed: _isSubmitting ? null : () => context.pop(),
                icon:
                    const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
                tooltip: 'Kembali',
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Enrollment Baru',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Pilih siswa dan batch untuk enrollment',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),

          // ── Form Card ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Data Enrollment'),
                  const SizedBox(height: AppDimensions.md),

                  // Student Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Siswa *',
                    ),
                    items: _students.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'] as String? ?? '',
                        child: Text(s['name'] as String? ?? ''),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (v) => setState(() => _selectedStudentId = v),
                    hint: const Text('Pilih siswa'),
                    validator: (v) =>
                        v == null ? 'Siswa wajib dipilih' : null,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Batch Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedBatchId,
                    decoration: const InputDecoration(
                      labelText: 'Batch *',
                    ),
                    items: _batches.map((b) {
                      return DropdownMenuItem<String>(
                        value: b['id'] as String? ?? '',
                        child: Text(b['name'] as String? ?? ''),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (v) => setState(() => _selectedBatchId = v),
                    hint: const Text('Pilih batch'),
                    validator: (v) =>
                        v == null ? 'Batch wajib dipilih' : null,
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // ── Action Buttons ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => context.pop(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimensions.xs),
        const Divider(color: AppColors.border),
      ],
    );
  }
}

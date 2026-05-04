import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../cubit/course_batch_cubit.dart';

class BatchFormPage extends StatelessWidget {
  const BatchFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseBatchCubit>(),
      child: const _BatchFormView(),
    );
  }
}

class _BatchFormView extends StatefulWidget {
  const _BatchFormView();

  @override
  State<_BatchFormView> createState() => _BatchFormViewState();
}

class _BatchFormViewState extends State<_BatchFormView> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _maxParticipantsCtrl = TextEditingController(text: '30');
  final _sessionsCtrl = TextEditingController(text: '8');

  String? _selectedCourseId;
  String? _selectedFacilitatorId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _facilitators = [];
  bool _loadingDropdowns = true;
  bool _isSubmitting = false;
  String? _dropdownError;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    _sessionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final results = await Future.wait([
        dio.get('/courses?limit=100'),
        dio.get('/departments?limit=100'),
      ]);

      final courseList = _parseList(results[0].data);
      final deptList = _parseList(results[1].data);

      // Flatten facilitators from all departments
      final facilitatorList = <Map<String, dynamic>>[];
      for (final dept in deptList) {
        if (dept['facilitators'] is List) {
          for (final f in dept['facilitators'] as List) {
            if (f is Map<String, dynamic>) {
              facilitatorList.add(f);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _courses = courseList;
          _facilitators = facilitatorList;
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course wajib dipilih'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai dan selesai wajib diisi'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'maxParticipants': int.tryParse(_maxParticipantsCtrl.text.trim()) ?? 30,
      'sessions': int.tryParse(_sessionsCtrl.text.trim()) ?? 8,
      'courseId': _selectedCourseId,
      'startDate':
          '${_startDate!.year.toString().padLeft(4, '0')}-'
          '${_startDate!.month.toString().padLeft(2, '0')}-'
          '${_startDate!.day.toString().padLeft(2, '0')}',
      'endDate':
          '${_endDate!.year.toString().padLeft(4, '0')}-'
          '${_endDate!.month.toString().padLeft(2, '0')}-'
          '${_endDate!.day.toString().padLeft(2, '0')}',
      'isActive': _isActive,
      if (_selectedFacilitatorId != null)
        'facilitatorId': _selectedFacilitatorId,
    };

    final success =
        await context.read<CourseBatchCubit>().createBatch(data);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch berhasil dibuat'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat batch'),
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
                      'Tambah Batch Baru',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Isi data untuk membuat batch baru',
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
                  _SectionTitle(title: 'Informasi Batch'),
                  const SizedBox(height: AppDimensions.md),

                  // Nama Batch
                  TextFormField(
                    controller: _nameCtrl,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Nama Batch *',
                      hintText: 'Masukkan nama batch',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama batch wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Course Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: 'Course *',
                    ),
                    items: _courses.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['id'] as String? ?? '',
                        child: Text(c['name'] as String? ?? ''),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (v) => setState(() => _selectedCourseId = v),
                    hint: const Text('Pilih course'),
                    validator: (v) =>
                        v == null ? 'Course wajib dipilih' : null,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Row: Max Participants + Sessions
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maxParticipantsCtrl,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Max Peserta *',
                            hintText: '30',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Harus berupa angka';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: TextFormField(
                          controller: _sessionsCtrl,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Sesi *',
                            hintText: '8',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Harus berupa angka';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Facilitator Dropdown (optional)
                  DropdownButtonFormField<String>(
                    value: _selectedFacilitatorId,
                    decoration: const InputDecoration(
                      labelText: 'Fasilitator',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tidak ada fasilitator'),
                      ),
                      ..._facilitators.map((f) {
                        return DropdownMenuItem<String>(
                          value: f['id'] as String? ?? '',
                          child: Text(f['name'] as String? ?? ''),
                        );
                      }),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (v) =>
                            setState(() => _selectedFacilitatorId = v),
                    hint: const Text('Pilih fasilitator (opsional)'),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Row: Start Date + End Date
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : _pickStartDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              enabled: !_isSubmitting,
                              decoration: InputDecoration(
                                labelText: 'Tanggal Mulai *',
                                hintText: 'Pilih tanggal',
                                suffixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: AppDimensions.iconMd),
                              ),
                              controller: TextEditingController(
                                text: _startDate != null
                                    ? '${_startDate!.day.toString().padLeft(2, '0')}/'
                                        '${_startDate!.month.toString().padLeft(2, '0')}/'
                                        '${_startDate!.year}'
                                    : '',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : _pickEndDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              enabled: !_isSubmitting,
                              decoration: InputDecoration(
                                labelText: 'Tanggal Selesai *',
                                hintText: 'Pilih tanggal',
                                suffixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: AppDimensions.iconMd),
                              ),
                              controller: TextEditingController(
                                text: _endDate != null
                                    ? '${_endDate!.day.toString().padLeft(2, '0')}/'
                                        '${_endDate!.month.toString().padLeft(2, '0')}/'
                                        '${_endDate!.year}'
                                    : '',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // isActive Switch
                  SwitchListTile(
                    value: _isActive,
                    onChanged:
                        _isSubmitting ? null : (v) => setState(() => _isActive = v),
                    title: const Text('Aktif'),
                    subtitle: Text(
                      _isActive
                          ? 'Batch aktif dan dapat dilihat'
                          : 'Batch tidak aktif',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
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

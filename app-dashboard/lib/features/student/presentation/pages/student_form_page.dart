import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../cubit/student_form_cubit.dart';
import '../cubit/student_form_state.dart';

class StudentFormPage extends StatelessWidget {
  final String? studentId;

  const StudentFormPage({super.key, this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StudentFormCubit>()..loadForm(studentId),
      child: _StudentFormView(studentId: studentId),
    );
  }
}

class _StudentFormView extends StatefulWidget {
  final String? studentId;
  const _StudentFormView({this.studentId});

  @override
  State<_StudentFormView> createState() => _StudentFormViewState();
}

class _StudentFormViewState extends State<_StudentFormView> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _studentCodeCtrl = TextEditingController();

  String? _selectedGender;
  String? _selectedDepartmentId;
  String _selectedStatus = 'aktif';
  DateTime? _selectedBirthDate;

  bool _initialized = false;

  bool get _isEdit => widget.studentId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nikCtrl.dispose();
    _addressCtrl.dispose();
    _studentCodeCtrl.dispose();
    super.dispose();
  }

  void _prefillFromState(StudentFormLoaded state) {
    if (_initialized || state.student == null) return;
    _initialized = true;

    final s = state.student!;
    _nameCtrl.text = s.name;
    _emailCtrl.text = s.email;
    _phoneCtrl.text = s.phone;
    _nikCtrl.text = s.nik ?? '';
    _addressCtrl.text = s.address ?? '';

    if (s.gender != null && s.gender!.isNotEmpty) {
      final g = s.gender!.toLowerCase();
      _selectedGender =
          (g == 'male' || g == 'laki-laki' || g == 'l') ? 'laki-laki' : 'perempuan';
    }

    if (s.departmentId.isNotEmpty) {
      final exists =
          state.departments.any((d) => d.id == s.departmentId);
      if (exists) _selectedDepartmentId = s.departmentId;
    }

    if (s.birthDate != null && s.birthDate!.isNotEmpty) {
      _selectedBirthDate = DateTime.tryParse(s.birthDate!);
    }

    // Map isActive to status
    _selectedStatus = s.isActive ? 'aktif' : 'tidak_aktif';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<StudentFormCubit>();
    await cubit.submit(
      studentId: widget.studentId,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      nik: _nikCtrl.text.trim().isEmpty ? null : _nikCtrl.text.trim(),
      gender: _selectedGender,
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      birthDate: _selectedBirthDate != null
          ? '${_selectedBirthDate!.year.toString().padLeft(4, '0')}-'
              '${_selectedBirthDate!.month.toString().padLeft(2, '0')}-'
              '${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
          : null,
      departmentId: _selectedDepartmentId,
      status: _selectedStatus,
      studentCode: _studentCodeCtrl.text.trim().isEmpty
          ? null
          : _studentCodeCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentFormCubit, StudentFormState>(
      listener: (context, state) {
        if (state is StudentFormLoaded) {
          _prefillFromState(state);
        }
        if (state is StudentFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
        if (state is StudentFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is StudentFormLoading || state is StudentFormInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is StudentFormError && state is! StudentFormLoaded) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppDimensions.md),
                Text(state.message,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: AppDimensions.md),
                FilledButton(
                  onPressed: () =>
                      context.read<StudentFormCubit>().loadForm(widget.studentId),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final isSubmitting = state is StudentFormSubmitting;
        final StudentFormLoaded? loadedState =
            state is StudentFormLoaded ? state : null;
        final departments = loadedState?.departments ?? <dynamic>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──────────────────────────────────────────────
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: isSubmitting ? null : () => context.pop(),
                    icon: const Icon(Icons.arrow_back,
                        size: AppDimensions.iconMd),
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Siswa' : 'Tambah Siswa Baru',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          _isEdit
                              ? 'Perbarui data siswa'
                              : 'Isi data lengkap siswa baru',
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
                      // Section: Data Pribadi
                      _SectionTitle(title: 'Data Pribadi'),
                      const SizedBox(height: AppDimensions.md),

                      // Nama
                      TextFormField(
                        controller: _nameCtrl,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap *',
                          hintText: 'Masukkan nama lengkap siswa',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama wajib diisi';
                          }
                          if (v.trim().length < 2) {
                            return 'Nama minimal 2 karakter';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          hintText: 'siswa@email.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(v.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Row: Telepon + NIK
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Telepon',
                                hintText: '08xxxxxxxxxx',
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: TextFormField(
                              controller: _nikCtrl,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'NIK',
                                hintText: '16 digit NIK',
                              ),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Row: Jenis Kelamin + Tanggal Lahir
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kelamin',
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'laki-laki',
                                    child: Text('Laki-laki')),
                                DropdownMenuItem(
                                    value: 'perempuan',
                                    child: Text('Perempuan')),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (v) =>
                                      setState(() => _selectedGender = v),
                              hint: const Text('Pilih jenis kelamin'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: GestureDetector(
                              onTap: isSubmitting ? null : _pickDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  enabled: !isSubmitting,
                                  decoration: InputDecoration(
                                    labelText: 'Tanggal Lahir',
                                    hintText: 'Pilih tanggal',
                                    suffixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: AppDimensions.iconMd),
                                  ),
                                  controller: TextEditingController(
                                    text: _selectedBirthDate != null
                                        ? '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/'
                                            '${_selectedBirthDate!.month.toString().padLeft(2, '0')}/'
                                            '${_selectedBirthDate!.year}'
                                        : '',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Alamat
                      TextFormField(
                        controller: _addressCtrl,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Alamat',
                          hintText: 'Masukkan alamat lengkap',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppDimensions.lg),

                      // Section: Data Akademik
                      _SectionTitle(title: 'Data Akademik'),
                      const SizedBox(height: AppDimensions.md),

                      // Row: Departemen + Status
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedDepartmentId,
                              decoration: const InputDecoration(
                                labelText: 'Departemen',
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Tidak ada departemen'),
                                ),
                                ...departments.map(
                                  (d) => DropdownMenuItem<String>(
                                    value: d.id as String,
                                    child: Text(d.name as String),
                                  ),
                                ),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (v) => setState(
                                      () => _selectedDepartmentId = v),
                              hint: const Text('Pilih departemen'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status *',
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'aktif', child: Text('Aktif')),
                                DropdownMenuItem(
                                    value: 'tidak_aktif',
                                    child: Text('Tidak Aktif')),
                                DropdownMenuItem(
                                    value: 'lulus', child: Text('Lulus')),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (v) => setState(
                                      () => _selectedStatus = v ?? 'aktif'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Kode Siswa
                      TextFormField(
                        controller: _studentCodeCtrl,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Kode Siswa',
                          hintText: 'Kode unik identifikasi siswa (opsional)',
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      // ── Action Buttons ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed:
                                isSubmitting ? null : () => context.pop(),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          FilledButton(
                            onPressed: isSubmitting ? null : _submit,
                            child: isSubmitting
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
      },
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/course_entity.dart';
import '../cubit/course_cubit.dart';

class CourseFormPage extends StatelessWidget {
  const CourseFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseCubit>(),
      child: const _CourseFormView(),
    );
  }
}

class _CourseFormView extends StatefulWidget {
  const _CourseFormView();

  @override
  State<_CourseFormView> createState() => _CourseFormViewState();
}

class _CourseFormViewState extends State<_CourseFormView> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _compCtrl = TextEditingController();

  CourseField _selectedField = CourseField.coding;
  final List<String> _competencies = [];
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _compCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
  );

  void _addCompetency() {
    final text = _compCtrl.text.trim();
    if (text.isNotEmpty && !_competencies.contains(text)) {
      setState(() => _competencies.add(text));
      _compCtrl.clear();
    }
  }

  void _removeCompetency(int index) {
    setState(() => _competencies.removeAt(index));
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode dan Nama Course wajib diisi'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final success = await context.read<CourseCubit>().createCourse({
        'course_code': code,
        'course_name': name,
        'field': _selectedField.name,
        'description': _descCtrl.text.trim(),
        'core_competencies': _competencies,
      });
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course berhasil dibuat'), backgroundColor: AppColors.success),
          );
          context.pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat course'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.outlined(
                onPressed: _saving ? null : () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
                tooltip: 'Kembali',
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buat Course Baru',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Tambahkan master course ke kurikulum',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          Container(
            padding: const EdgeInsets.all(AppDimensions.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: course code + name
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        decoration: _dec('Kode Course', hint: 'COD-001'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: _dec('Nama Course'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),

                // Field dropdown
                DropdownButtonFormField<CourseField>(
                  initialValue: _selectedField,
                  decoration: _dec('Bidang'),
                  items: CourseField.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedField = v);
                  },
                ),
                const SizedBox(height: AppDimensions.md),

                // Description
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: _dec('Deskripsi'),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Core Competencies
                Text('Core Competencies',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _compCtrl,
                        decoration: _dec('Tambah Kompetensi', hint: 'Ketik lalu tepan Add'),
                        onSubmitted: (_) => _addCompetency(),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    FilledButton.tonal(
                      onPressed: _addCompetency,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                if (_competencies.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.sm),
                  Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.sm,
                    children: [
                      for (var i = 0; i < _competencies.length; i++)
                        Chip(
                          label: Text(_competencies[i]),
                          onDeleted: () => _removeCompetency(i),
                          deleteIconColor: AppColors.error,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.xl),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => context.pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Buat Course'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

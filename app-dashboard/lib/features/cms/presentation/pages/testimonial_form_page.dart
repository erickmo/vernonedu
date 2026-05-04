import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/cms_testimonial_entity.dart';
import '../cubit/cms_cubit.dart';

class TestimonialFormPage extends StatelessWidget {
  final CmsTestimonialEntity? testimonial;

  const TestimonialFormPage({super.key, this.testimonial});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CmsCubit>(),
      child: _TestimonialFormView(testimonial: testimonial),
    );
  }
}

class _TestimonialFormView extends StatefulWidget {
  final CmsTestimonialEntity? testimonial;
  const _TestimonialFormView({this.testimonial});

  @override
  State<_TestimonialFormView> createState() => _TestimonialFormViewState();
}

class _TestimonialFormViewState extends State<_TestimonialFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _quoteCtrl = TextEditingController();
  int _rating = 5;
  bool _featured = false;
  bool _saving = false;

  bool get _isEdit => widget.testimonial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.testimonial;
    if (t != null) {
      _nameCtrl.text = t.studentName;
      _courseCtrl.text = t.courseName;
      _quoteCtrl.text = t.quote;
      _rating = t.rating;
      _featured = t.isFeatured;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    _quoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'student_name': _nameCtrl.text.trim(),
        'course_name': _courseCtrl.text.trim(),
        'quote': _quoteCtrl.text.trim(),
        'rating': _rating,
        'is_featured': _featured,
      };
      if (_isEdit) {
        await context
            .read<CmsCubit>()
            .updateTestimonial(widget.testimonial!.id, data);
      } else {
        await context.read<CmsCubit>().createTestimonial(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Testimoni berhasil diperbarui'
                : 'Testimoni berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
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
          // Back button + title row
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
                    Text(
                      _isEdit ? 'Edit Testimoni' : 'Tambah Testimoni',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    Text(
                      _isEdit
                          ? 'Perbarui testimoni siswa'
                          : 'Tambah testimoni baru',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),

          // Form card
          Container(
            padding: const EdgeInsets.all(AppDimensions.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Siswa
                  TextFormField(
                    controller: _nameCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Nama siswa wajib diisi'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Nama Siswa',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Kursus
                  TextFormField(
                    controller: _courseCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Kursus wajib diisi'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Kursus',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Quote
                  TextFormField(
                    controller: _quoteCtrl,
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Quote wajib diisi'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Quote',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Rating
                  Text(
                    'Rating',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => _rating = i + 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),

                  // Featured toggle
                  SwitchListTile(
                    title: const Text('Featured (tampil di beranda)'),
                    value: _featured,
                    onChanged: (v) => setState(() => _featured = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // Actions
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
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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

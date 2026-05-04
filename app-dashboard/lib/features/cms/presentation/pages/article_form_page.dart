import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/cms_article_entity.dart';
import '../cubit/cms_cubit.dart';

class ArticleFormPage extends StatelessWidget {
  final CmsArticleEntity? article;
  const ArticleFormPage({super.key, this.article});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CmsCubit>(),
      child: _ArticleFormView(article: article),
    );
  }
}

class _ArticleFormView extends StatefulWidget {
  final CmsArticleEntity? article;
  const _ArticleFormView({this.article});

  @override
  State<_ArticleFormView> createState() => _ArticleFormViewState();
}

class _ArticleFormViewState extends State<_ArticleFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();
  String _category = 'tips_karir';
  String _status = 'draft';
  bool _saving = false;

  bool get _isEdit => widget.article != null;

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    if (a != null) {
      _titleCtrl.text = a.title;
      _slugCtrl.text = a.slug;
      _contentCtrl.text = a.content;
      _metaTitleCtrl.text = a.metaTitle;
      _metaDescCtrl.text = a.metaDescription;
      _category = a.category;
      _status = a.status;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    _contentCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'slug': _slugCtrl.text.trim(),
        'category': _category,
        'content': _contentCtrl.text.trim(),
        'status': _status,
        'seo': {
          'meta_title': _metaTitleCtrl.text.trim(),
          'meta_description': _metaDescCtrl.text.trim(),
        },
      };
      if (_isEdit) {
        await context.read<CmsCubit>().updateArticle(widget.article!.id, data);
      } else {
        await context.read<CmsCubit>().createArticle(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Artikel berhasil diperbarui'
                  : 'Artikel berhasil dibuat',
            ),
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
          // Header row with back button and title
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
                      _isEdit ? 'Edit Artikel' : 'Buat Artikel Baru',
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
                          ? 'Perbarui konten artikel'
                          : 'Tulis artikel baru',
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
                  // Title
                  TextFormField(
                    controller: _titleCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                    decoration: _dec('Judul'),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Slug
                  TextFormField(
                    controller: _slugCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Slug wajib diisi' : null,
                    decoration: _dec('Slug'),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Category + Status row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: _dec('Kategori'),
                          items: const [
                            DropdownMenuItem(
                                value: 'tips_karir', child: Text('Tips Karir')),
                            DropdownMenuItem(
                                value: 'info_kursus', child: Text('Info Kursus')),
                            DropdownMenuItem(value: 'berita', child: Text('Berita')),
                            DropdownMenuItem(value: 'event', child: Text('Event')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: _dec('Status'),
                          items: const [
                            DropdownMenuItem(value: 'draft', child: Text('Draft')),
                            DropdownMenuItem(
                                value: 'published', child: Text('Published')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Content
                  TextFormField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    decoration: _dec('Konten'),
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // SEO section header
                  const Text(
                    'SEO',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),

                  // Meta Title
                  TextFormField(
                    controller: _metaTitleCtrl,
                    decoration: _dec('Meta Title'),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Meta Description
                  TextFormField(
                    controller: _metaDescCtrl,
                    maxLines: 3,
                    decoration: _dec('Meta Description'),
                  ),
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
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isEdit ? 'Simpan' : 'Buat'),
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

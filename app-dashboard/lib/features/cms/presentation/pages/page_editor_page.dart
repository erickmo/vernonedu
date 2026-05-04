import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/cms_page_entity.dart';
import '../cubit/cms_cubit.dart';

class PageEditorPage extends StatelessWidget {
  final CmsPageEntity page;
  const PageEditorPage({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CmsCubit>(),
      child: _PageEditorView(page: page),
    );
  }
}

class _PageEditorView extends StatefulWidget {
  final CmsPageEntity page;
  const _PageEditorView({required this.page});

  @override
  State<_PageEditorView> createState() => _PageEditorViewState();
}

class _PageEditorViewState extends State<_PageEditorView> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.page.title;
    _subtitleCtrl.text = widget.page.subtitle;
    _metaTitleCtrl.text = widget.page.metaTitle;
    _metaDescCtrl.text = widget.page.metaDescription;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
  );

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await context.read<CmsCubit>().savePage(widget.page.slug, {
        'title': _titleCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'seo': {
          'meta_title': _metaTitleCtrl.text.trim(),
          'meta_description': _metaDescCtrl.text.trim(),
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Halaman berhasil disimpan'), backgroundColor: AppColors.success),
        );
        context.pop(true);
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
                    Text('Edit Halaman: ${widget.page.slug}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Perbarui konten halaman',
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
                TextField(controller: _titleCtrl, decoration: _dec('Judul Halaman')),
                const SizedBox(height: AppDimensions.md),
                TextField(controller: _subtitleCtrl, decoration: _dec('Subtitle')),
                const SizedBox(height: AppDimensions.lg),
                Text('SEO', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: AppDimensions.sm),
                TextField(controller: _metaTitleCtrl, decoration: _dec('Meta Title')),
                const SizedBox(height: AppDimensions.md),
                TextField(controller: _metaDescCtrl, maxLines: 3, decoration: _dec('Meta Description')),
                const SizedBox(height: AppDimensions.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: _saving ? null : () => context.pop(), child: const Text('Batal')),
                    const SizedBox(width: AppDimensions.md),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Simpan'),
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

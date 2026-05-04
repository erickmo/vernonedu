import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/social_media_post_entity.dart';
import '../cubit/marketing_cubit.dart';

class SocialPostFormPage extends StatelessWidget {
  final SocialMediaPostEntity? post;

  const SocialPostFormPage({super.key, this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => context.read<MarketingCubit>(),
      child: _SocialPostFormView(post: post),
    );
  }
}

class _SocialPostFormView extends StatefulWidget {
  final SocialMediaPostEntity? post;
  const _SocialPostFormView({this.post});

  @override
  State<_SocialPostFormView> createState() => _SocialPostFormViewState();
}

class _SocialPostFormViewState extends State<_SocialPostFormView> {
  final _formKey = GlobalKey<FormState>();

  final _captionCtrl = TextEditingController();
  final _mediaUrlCtrl = TextEditingController();

  List<String> _selectedPlatforms = [];
  String _contentType = 'promo';
  DateTime? _scheduledAt;

  bool _isSubmitting = false;
  bool _initialized = false;

  bool get _isEdit => widget.post != null;

  static const _platformOptions = [
    'instagram',
    'facebook',
    'tiktok',
    'youtube',
    'linkedin',
    'twitter',
  ];

  static const _contentTypeOptions = {
    'promo': 'Promosi Course',
    'dokumentasi': 'Dokumentasi Kelas',
    'event': 'Event',
    'info': 'Info Umum',
  };

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _prefillFromEntity();
    }
  }

  void _prefillFromEntity() {
    if (_initialized) return;
    _initialized = true;

    final p = widget.post!;
    _captionCtrl.text = p.caption;
    _mediaUrlCtrl.text = p.mediaUrl;
    _contentType = p.contentType;
    _selectedPlatforms = List.from(p.platforms);
    _scheduledAt = p.scheduledAt;
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _mediaUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledAt = picked);
    }
  }

  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu platform'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'platforms': _selectedPlatforms,
      'contentType': _contentType,
      'caption': _captionCtrl.text.trim(),
      'mediaUrl': _mediaUrlCtrl.text.trim(),
      if (_scheduledAt != null)
        'scheduledAt':
            '${_scheduledAt!.year.toString().padLeft(4, '0')}-'
            '${_scheduledAt!.month.toString().padLeft(2, '0')}-'
            '${_scheduledAt!.day.toString().padLeft(2, '0')}',
    };

    final cubit = context.read<MarketingCubit>();
    final bool success;
    if (_isEdit) {
      success = await cubit.updatePost(widget.post!.id, data);
    } else {
      success = await cubit.createPost(data);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Post berhasil diperbarui'
              : 'Post berhasil dibuat'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Gagal memperbarui post'
              : 'Gagal membuat post'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _isEdit ? 'Edit Social Media Post' : 'Tambah Post Baru',
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
                          ? 'Perbarui konten social media post'
                          : 'Isi data untuk membuat post baru',
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
                  _SectionTitle(title: 'Konten Post'),
                  const SizedBox(height: AppDimensions.md),

                  // Platforms Checkboxes
                  Text(
                    'Platform *',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.sm,
                    children: _platformOptions.map((platform) {
                      final isSelected =
                          _selectedPlatforms.contains(platform);
                      return FilterChip(
                        label: Text(platform),
                        selected: isSelected,
                        onSelected: _isSubmitting
                            ? null
                            : (_) => _togglePlatform(platform),
                        selectedColor: AppColors.primarySurface,
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Content Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _contentType,
                    decoration: const InputDecoration(
                      labelText: 'Tipe Konten *',
                    ),
                    items: _contentTypeOptions.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (v) =>
                            setState(() => _contentType = v ?? 'promo'),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Caption
                  TextFormField(
                    controller: _captionCtrl,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Caption *',
                      hintText: 'Tulis caption untuk post',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Caption wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Media URL
                  TextFormField(
                    controller: _mediaUrlCtrl,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Media URL',
                      hintText: 'https://example.com/image.jpg',
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Scheduled At
                  GestureDetector(
                    onTap: _isSubmitting ? null : _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          labelText: 'Jadwal Post',
                          hintText: 'Pilih tanggal',
                          suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: AppDimensions.iconMd),
                        ),
                        controller: TextEditingController(
                          text: _scheduledAt != null
                              ? '${_scheduledAt!.day.toString().padLeft(2, '0')}/'
                                  '${_scheduledAt!.month.toString().padLeft(2, '0')}/'
                                  '${_scheduledAt!.year}'
                              : '',
                        ),
                      ),
                    ),
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

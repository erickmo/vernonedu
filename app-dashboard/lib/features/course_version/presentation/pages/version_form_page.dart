import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/course_version_entity.dart';
import '../cubit/course_version_cubit.dart';

class VersionFormPage extends StatelessWidget {
  final String typeId;
  final String? typeName;
  final List<CourseVersionEntity> existingVersions;

  const VersionFormPage({
    super.key,
    required this.typeId,
    this.typeName,
    this.existingVersions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseVersionCubit>(),
      child: _VersionFormView(
        typeId: typeId,
        typeName: typeName,
        existingVersions: existingVersions,
      ),
    );
  }
}

class _VersionFormView extends StatefulWidget {
  final String typeId;
  final String? typeName;
  final List<CourseVersionEntity> existingVersions;

  const _VersionFormView({
    required this.typeId,
    this.typeName,
    required this.existingVersions,
  });

  @override
  State<_VersionFormView> createState() => _VersionFormViewState();
}

class _VersionFormViewState extends State<_VersionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _changelogCtrl = TextEditingController();
  String _changeType = 'minor';
  bool _saving = false;

  static const _changeTypeOptions = [
    ('major', 'Major (perubahan besar)'),
    ('minor', 'Minor (fitur/perbaikan)'),
    ('patch', 'Patch (koreksi kecil)'),
  ];

  late final String _autoVersion;

  @override
  void initState() {
    super.initState();
    _autoVersion = _calculateNextVersion(widget.existingVersions);
  }

  @override
  void dispose() {
    _changelogCtrl.dispose();
    super.dispose();
  }

  String _calculateNextVersion(List<CourseVersionEntity> versions) {
    if (versions.isEmpty) return '1.0.0';

    // Sort by version number descending to find the latest
    final sorted = List<CourseVersionEntity>.from(versions)
      ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));

    final latest = sorted.first.versionNumber;
    final parts = latest.split('.').map(int.parse).toList();

    // Increment minor by default
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1] + 1}.0';
    } else if (parts.length == 2) {
      return '${parts[0]}.${parts[1] + 1}.0';
    }
    return '${parts[0] + 1}.0.0';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'version_number': _autoVersion,
        'change_type': _changeType,
        'changelog': _changelogCtrl.text.trim(),
      };

      final success = await context
          .read<CourseVersionCubit>()
          .createVersion(widget.typeId, data, typeName: widget.typeName);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Versi berhasil dibuat'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat versi: $e'),
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
          // ── Top Bar ──────────────────────────────────────────────
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
                      'Buat Versi Baru',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Tambahkan versi kurikulum baru untuk tipe course ini',
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

          // ── Form Card ─────────────────────────────────────────────
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
                  // Version Number (read-only, auto-calculated)
                  TextFormField(
                    enabled: false,
                    initialValue: _autoVersion,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Versi',
                      hintText: 'Auto-calculated',
                      prefixIcon: Icon(Icons.tag, size: AppDimensions.iconMd),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Change Type
                  DropdownButtonFormField<String>(
                    value: _changeType,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Perubahan *',
                      prefixIcon:
                          Icon(Icons.swap_vert, size: AppDimensions.iconMd),
                    ),
                    items: _changeTypeOptions
                        .map((e) => DropdownMenuItem(
                              value: e.$1,
                              child: Text(e.$2),
                            ))
                        .toList(),
                    onChanged:
                        _saving ? null : (v) => setState(() => _changeType = v!),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Changelog
                  TextFormField(
                    controller: _changelogCtrl,
                    enabled: !_saving,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Changelog *',
                      hintText: 'Deskripsikan perubahan pada versi ini',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Changelog wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // ── Action Buttons ──────────────────────────────────
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
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Buat Versi'),
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

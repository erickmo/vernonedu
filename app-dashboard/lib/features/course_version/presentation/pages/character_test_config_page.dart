import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/character_test_config_entity.dart';
import '../cubit/course_version_cubit.dart';

class CharacterTestConfigPage extends StatelessWidget {
  final String versionId;
  final CharacterTestConfigEntity? existingConfig;

  const CharacterTestConfigPage({
    super.key,
    required this.versionId,
    this.existingConfig,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseVersionCubit>(),
      child: _CharacterTestConfigView(
        versionId: versionId,
        existingConfig: existingConfig,
      ),
    );
  }
}

class _CharacterTestConfigView extends StatefulWidget {
  final String versionId;
  final CharacterTestConfigEntity? existingConfig;

  const _CharacterTestConfigView({
    required this.versionId,
    this.existingConfig,
  });

  @override
  State<_CharacterTestConfigView> createState() =>
      _CharacterTestConfigViewState();
}

class _CharacterTestConfigViewState extends State<_CharacterTestConfigView> {
  final _formKey = GlobalKey<FormState>();
  final _testProviderCtrl = TextEditingController();
  final _passingThresholdCtrl = TextEditingController();
  String _testType = 'MBTI';
  bool _talentpoolEligible = false;
  bool _saving = false;

  static const _testTypeOptions = [
    ('MBTI', 'MBTI Test'),
    ('DISC', 'DISC Assessment'),
    ('custom', 'Custom Test'),
  ];

  bool get _isEdit => widget.existingConfig != null;

  @override
  void initState() {
    super.initState();
    _prefillFromEntity();
  }

  void _prefillFromEntity() {
    final config = widget.existingConfig;
    if (config == null) return;

    _testType = config.testType;
    _testProviderCtrl.text = config.testProvider;
    _passingThresholdCtrl.text = config.passingThreshold.toString();
    _talentpoolEligible = config.talentpoolEligible;
  }

  @override
  void dispose() {
    _testProviderCtrl.dispose();
    _passingThresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'test_type': _testType,
        'test_provider': _testProviderCtrl.text.trim(),
        'passing_threshold':
            double.tryParse(_passingThresholdCtrl.text.trim()) ?? 0.0,
        'talentpool_eligible': _talentpoolEligible,
      };

      final success = await context
          .read<CourseVersionCubit>()
          .saveCharacterTestConfig(widget.versionId, data);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Konfigurasi tes karakter berhasil diperbarui'
                : 'Konfigurasi tes karakter berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
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
                      _isEdit
                          ? 'Edit Konfigurasi Tes Karakter'
                          : 'Konfigurasi Tes Karakter',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Atur tes karakter/mindset untuk pipeline talent pool',
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
                  // Test Type
                  DropdownButtonFormField<String>(
                    value: _testType,
                    decoration: const InputDecoration(
                      labelText: 'Tipe Tes *',
                      prefixIcon:
                          Icon(Icons.quiz, size: AppDimensions.iconMd),
                    ),
                    items: _testTypeOptions
                        .map((e) => DropdownMenuItem(
                              value: e.$1,
                              child: Text(e.$2),
                            ))
                        .toList(),
                    onChanged:
                        _saving ? null : (v) => setState(() => _testType = v!),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Test Provider
                  TextFormField(
                    controller: _testProviderCtrl,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Penyedia Tes *',
                      hintText: 'Nama provider atau platform tes',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Penyedia tes wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Passing Threshold
                  TextFormField(
                    controller: _passingThresholdCtrl,
                    enabled: !_saving,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Ambang Batas Kelulusan *',
                      hintText: 'Contoh: 75.0',
                      suffixText: '/ 100',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ambang batas wajib diisi';
                      }
                      final threshold = double.tryParse(v.trim());
                      if (threshold == null) {
                        return 'Harus berupa angka';
                      }
                      if (threshold < 0 || threshold > 100) {
                        return 'Nilai harus antara 0-100';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Talentpool Eligible
                  SwitchListTile(
                    value: _talentpoolEligible,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _talentpoolEligible = v),
                    title: const Text('Eligible untuk Talent Pool'),
                    subtitle: const Text(
                        'Lulus tes ini otomatis masuk kandidat talent pool'),
                    contentPadding: EdgeInsets.zero,
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

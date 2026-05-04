import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/internship_config_entity.dart';
import '../cubit/course_version_cubit.dart';

class InternshipConfigPage extends StatelessWidget {
  final String versionId;
  final InternshipConfigEntity? existingConfig;

  const InternshipConfigPage({
    super.key,
    required this.versionId,
    this.existingConfig,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseVersionCubit>(),
      child: _InternshipConfigView(
        versionId: versionId,
        existingConfig: existingConfig,
      ),
    );
  }
}

class _InternshipConfigView extends StatefulWidget {
  final String versionId;
  final InternshipConfigEntity? existingConfig;

  const _InternshipConfigView({
    required this.versionId,
    this.existingConfig,
  });

  @override
  State<_InternshipConfigView> createState() => _InternshipConfigViewState();
}

class _InternshipConfigViewState extends State<_InternshipConfigView> {
  final _formKey = GlobalKey<FormState>();
  final _partnerCompanyNameCtrl = TextEditingController();
  final _positionTitleCtrl = TextEditingController();
  final _durationWeeksCtrl = TextEditingController();
  final _supervisorNameCtrl = TextEditingController();
  final _supervisorContactCtrl = TextEditingController();
  final _mouDocumentUrlCtrl = TextEditingController();
  bool _isCompanyProvided = false;
  bool _saving = false;

  bool get _isEdit => widget.existingConfig != null;

  @override
  void initState() {
    super.initState();
    _prefillFromEntity();
  }

  void _prefillFromEntity() {
    final config = widget.existingConfig;
    if (config == null) return;

    _partnerCompanyNameCtrl.text = config.partnerCompanyName;
    _positionTitleCtrl.text = config.positionTitle;
    _durationWeeksCtrl.text = config.durationWeeks.toString();
    _supervisorNameCtrl.text = config.supervisorName;
    _supervisorContactCtrl.text = config.supervisorContact;
    _mouDocumentUrlCtrl.text = config.mouDocumentUrl;
    _isCompanyProvided = config.isCompanyProvided;
  }

  @override
  void dispose() {
    _partnerCompanyNameCtrl.dispose();
    _positionTitleCtrl.dispose();
    _durationWeeksCtrl.dispose();
    _supervisorNameCtrl.dispose();
    _supervisorContactCtrl.dispose();
    _mouDocumentUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'partner_company_name': _partnerCompanyNameCtrl.text.trim(),
        'position_title': _positionTitleCtrl.text.trim(),
        'duration_weeks': int.tryParse(_durationWeeksCtrl.text.trim()) ?? 0,
        'supervisor_name': _supervisorNameCtrl.text.trim(),
        'supervisor_contact': _supervisorContactCtrl.text.trim(),
        'mou_document_url': _mouDocumentUrlCtrl.text.trim(),
        'is_company_provided': _isCompanyProvided,
      };

      final success = await context
          .read<CourseVersionCubit>()
          .saveInternshipConfig(widget.versionId, data);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Konfigurasi magang berhasil diperbarui'
                : 'Konfigurasi magang berhasil disimpan'),
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
                          ? 'Edit Konfigurasi Magang'
                          : 'Konfigurasi Magang',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Atur detail program magang untuk versi ini',
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
                  // Section: Partner Info
                  _SectionTitle(title: 'Informasi Partner'),
                  const SizedBox(height: AppDimensions.md),

                  // Partner Company Name
                  TextFormField(
                    controller: _partnerCompanyNameCtrl,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan Partner *',
                      hintText: 'Nama perusahaan tempat magang',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama perusahaan wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Position Title
                  TextFormField(
                    controller: _positionTitleCtrl,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Posisi / Jabatan *',
                      hintText: 'Contoh: Frontend Developer Intern',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Posisi wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Duration Weeks
                  TextFormField(
                    controller: _durationWeeksCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durasi (minggu) *',
                      hintText: 'Contoh: 12',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Durasi wajib diisi';
                      }
                      final weeks = int.tryParse(v.trim());
                      if (weeks == null || weeks < 1) {
                        return 'Durasi harus angka positif';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Section: Supervisor
                  _SectionTitle(title: 'Supervisor'),
                  const SizedBox(height: AppDimensions.md),

                  // Row: Supervisor Name + Contact
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _supervisorNameCtrl,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Nama Supervisor',
                            hintText: 'Nama pembimbing',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: TextFormField(
                          controller: _supervisorContactCtrl,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Kontak Supervisor',
                            hintText: 'Email / telepon',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Section: Dokumen & Opsi
                  _SectionTitle(title: 'Dokumen & Opsi'),
                  const SizedBox(height: AppDimensions.md),

                  // MOU Document URL
                  TextFormField(
                    controller: _mouDocumentUrlCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL Dokumen MoU',
                      hintText: 'https://...',
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Is Company Provided
                  SwitchListTile(
                    value: _isCompanyProvided,
                    onChanged:
                        _saving ? null : (v) => setState(() => _isCompanyProvided = v),
                    title: const Text('Perusahaan disediakan'),
                    subtitle: const Text(
                        'Aktifkan jika perusahaan magang disediakan oleh pihak penyelenggara'),
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

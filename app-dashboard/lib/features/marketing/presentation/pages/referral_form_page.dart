import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/referral_partner_entity.dart';
import '../cubit/marketing_cubit.dart';

class ReferralFormPage extends StatelessWidget {
  final ReferralPartnerEntity? partner;

  const ReferralFormPage({super.key, this.partner});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MarketingCubit>(),
      child: _ReferralFormView(partner: partner),
    );
  }
}

class _ReferralFormView extends StatefulWidget {
  final ReferralPartnerEntity? partner;
  const _ReferralFormView({this.partner});

  @override
  State<_ReferralFormView> createState() => _ReferralFormViewState();
}

class _ReferralFormViewState extends State<_ReferralFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _referralCodeCtrl = TextEditingController();
  final _commissionValueCtrl = TextEditingController();
  String _commissionType = 'percentage';
  bool _saving = false;

  static const _commissionTypeOptions = [
    ('percentage', 'Persentase (%)'),
    ('fixed', 'Nominal Tetap (Rp)'),
  ];

  bool get _isEdit => widget.partner != null;

  @override
  void initState() {
    super.initState();
    _prefillFromEntity();
  }

  void _prefillFromEntity() {
    final p = widget.partner;
    if (p == null) return;

    _nameCtrl.text = p.name;
    _contactEmailCtrl.text = p.contactEmail;
    _referralCodeCtrl.text = p.referralCode;
    _commissionType = p.commissionType;
    _commissionValueCtrl.text = p.commissionValue.toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _referralCodeCtrl.dispose();
    _commissionValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'contact_email': _contactEmailCtrl.text.trim(),
        'referral_code': _referralCodeCtrl.text.trim(),
        'commission_type': _commissionType,
        'commission_value':
            double.tryParse(_commissionValueCtrl.text.trim()) ?? 0.0,
      };

      bool success;
      if (_isEdit) {
        success = await context
            .read<MarketingCubit>()
            .updateReferralPartner(widget.partner!.id, data);
      } else {
        success =
            await context.read<MarketingCubit>().createReferralPartner(data);
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Partner referral berhasil diperbarui'
                : 'Partner referral berhasil ditambahkan'),
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
                          ? 'Edit Partner Referral'
                          : 'Tambah Partner Referral',
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
                          ? 'Perbarui data partner referral'
                          : 'Daftarkan partner referral baru',
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
                  // Name
                  TextFormField(
                    controller: _nameCtrl,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Nama Partner *',
                      hintText: 'Nama lengkap partner',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama partner wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Contact Email
                  TextFormField(
                    controller: _contactEmailCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Kontak',
                      hintText: 'partner@email.com',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Referral Code
                  TextFormField(
                    controller: _referralCodeCtrl,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Kode Referral',
                      hintText: 'Kode unik referral (opsional)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Row: Commission Type + Value
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _commissionType,
                          decoration: const InputDecoration(
                            labelText: 'Tipe Komisi',
                          ),
                          items: _commissionTypeOptions
                              .map((e) => DropdownMenuItem(
                                    value: e.$1,
                                    child: Text(e.$2),
                                  ))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _commissionType = v!),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _commissionValueCtrl,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Nilai Komisi',
                            hintText: '0.0',
                            suffixText: _commissionType == 'percentage'
                                ? '%'
                                : 'Rp',
                          ),
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final val = double.tryParse(v.trim());
                              if (val == null || val < 0) {
                                return 'Nilai harus angka positif';
                              }
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ],
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
                            : Text(_isEdit ? 'Update' : 'Simpan'),
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

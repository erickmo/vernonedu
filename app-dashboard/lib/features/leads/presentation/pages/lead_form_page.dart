import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/lead_entity.dart';
import '../cubit/lead_cubit.dart';

class LeadFormPage extends StatelessWidget {
  final LeadEntity? lead;
  const LeadFormPage({super.key, this.lead});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeadCubit>(),
      child: _LeadFormView(lead: lead),
    );
  }
}

class _LeadFormView extends StatefulWidget {
  final LeadEntity? lead;
  const _LeadFormView({this.lead});

  @override
  State<_LeadFormView> createState() => _LeadFormViewState();
}

class _LeadFormViewState extends State<_LeadFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _source = 'referral';
  String _status = 'new';
  bool _saving = false;

  static const _sourceOptions = [
    ('referral', 'Referral'),
    ('social_media', 'Media Sosial'),
    ('walk_in', 'Walk In'),
    ('website', 'Website'),
  ];
  static const _statusOptions = [
    ('new', 'Baru'),
    ('contacted', 'Dihubungi'),
    ('interested', 'Tertarik'),
    ('negotiating', 'Negosiasi'),
    ('enrolled', 'Terdaftar'),
    ('not_interested', 'Tidak Tertarik'),
  ];

  bool get _isEdit => widget.lead != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    if (l != null) {
      _nameCtrl.text = l.name;
      _emailCtrl.text = l.email;
      _phoneCtrl.text = l.phone;
      _interestCtrl.text = l.interest;
      _notesCtrl.text = l.notes;
      _source = l.source;
      _status = l.status;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _interestCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'interest': _interestCtrl.text.trim(),
        'source': _source,
        'notes': _notesCtrl.text.trim(),
      };
      if (_isEdit) {
        data['status'] = _status;
        await context.read<LeadCubit>().updateLead(widget.lead!.id, data);
      } else {
        await context.read<LeadCubit>().createLead(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Lead berhasil diperbarui'
                : 'Lead berhasil ditambahkan'),
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
                      _isEdit ? 'Edit Lead' : 'Tambah Lead',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    Text(
                      _isEdit
                          ? 'Perbarui data lead'
                          : 'Tambah calon siswa baru',
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
                  TextFormField(
                    controller: _nameCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    decoration: InputDecoration(
                      labelText: 'Nama *',
                      hintText: 'Nama calon siswa',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'contoh@email.com',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon',
                      hintText: '08xxxxxxxxxx',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _interestCtrl,
                    decoration: InputDecoration(
                      labelText: 'Minat Program',
                      hintText: 'Program yang diminati',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  DropdownButtonFormField<String>(
                    value: _source,
                    decoration: InputDecoration(
                      labelText: 'Sumber',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                    items: _sourceOptions
                        .map((e) => DropdownMenuItem(
                              value: e.$1,
                              child: Text(e.$2),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _source = v);
                    },
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: AppDimensions.md),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                      items: _statusOptions
                          .map((e) => DropdownMenuItem(
                                value: e.$1,
                                child: Text(e.$2),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ],
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Catatan',
                      hintText: 'Catatan tambahan',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
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

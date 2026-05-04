import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/cms_faq_entity.dart';
import '../cubit/cms_cubit.dart';

class FaqFormPage extends StatelessWidget {
  final String? faqId;
  final CmsFaqEntity? faq;

  const FaqFormPage({super.key, this.faqId, this.faq});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CmsCubit>(),
      child: _FaqFormView(faq: faq),
    );
  }
}

class _FaqFormView extends StatefulWidget {
  final CmsFaqEntity? faq;
  const _FaqFormView({this.faq});

  @override
  State<_FaqFormView> createState() => _FaqFormViewState();
}

class _FaqFormViewState extends State<_FaqFormView> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  String _category = 'umum';
  bool _saving = false;

  bool get _isEdit => widget.faq != null;

  @override
  void initState() {
    super.initState();
    final f = widget.faq;
    if (f != null) {
      _questionCtrl.text = f.question;
      _answerCtrl.text = f.answer;
      _category = f.category;
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'question': _questionCtrl.text.trim(),
        'answer': _answerCtrl.text.trim(),
        'category': _category,
      };
      if (_isEdit) {
        await context.read<CmsCubit>().updateFaq(widget.faq!.id, data);
      } else {
        await context.read<CmsCubit>().createFaq(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'FAQ berhasil diperbarui'
                : 'FAQ berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'), backgroundColor: AppColors.error),
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
                      _isEdit ? 'Edit FAQ' : 'Tambah FAQ',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    Text(
                      _isEdit
                          ? 'Perbarui pertanyaan FAQ'
                          : 'Tambah pertanyaan FAQ baru',
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
                    controller: _questionCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Pertanyaan wajib diisi'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Pertanyaan',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _answerCtrl,
                    maxLines: 5,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Jawaban wajib diisi'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Jawaban',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'umum', child: Text('Umum')),
                      DropdownMenuItem(
                          value: 'pendaftaran', child: Text('Pendaftaran')),
                      DropdownMenuItem(
                          value: 'pembayaran', child: Text('Pembayaran')),
                      DropdownMenuItem(
                          value: 'sertifikat', child: Text('Sertifikat')),
                      DropdownMenuItem(
                          value: 'program_karir',
                          child: Text('Program Karir')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
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
                                    strokeWidth: 2, color: Colors.white))
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

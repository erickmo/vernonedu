import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class CoaFormPage extends StatefulWidget {
  const CoaFormPage({super.key});

  @override
  State<CoaFormPage> createState() => _CoaFormPageState();
}

class _CoaFormPageState extends State<CoaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _type = 'asset';
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await getIt<ApiClient>().dio.post('/finance/coa', data: {
        'code': _codeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'account_type': _type,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil ditambahkan'), backgroundColor: AppColors.success),
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
          // Back button + title row (same as StudentFormPage)
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
                    Text('Tambah Akun Baru', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Tambah akun baru ke Chart of Accounts', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
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
                  TextFormField(
                    controller: _codeCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode wajib diisi' : null,
                    decoration: InputDecoration(
                      labelText: 'Kode Akun',
                      hintText: 'misal: 1101',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _nameCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    decoration: InputDecoration(
                      labelText: 'Nama Akun',
                      hintText: 'misal: Kas',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: InputDecoration(
                      labelText: 'Tipe Akun',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'asset', child: Text('Aset')),
                      DropdownMenuItem(value: 'liability', child: Text('Kewajiban')),
                      DropdownMenuItem(value: 'equity', child: Text('Ekuitas')),
                      DropdownMenuItem(value: 'revenue', child: Text('Pendapatan')),
                      DropdownMenuItem(value: 'expense', child: Text('Beban')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _type = v); },
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  // Buttons
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
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

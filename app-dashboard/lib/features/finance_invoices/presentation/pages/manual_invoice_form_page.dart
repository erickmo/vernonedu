import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../cubit/invoice_cubit.dart';

class ManualInvoiceFormPage extends StatelessWidget {
  const ManualInvoiceFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InvoiceCubit>(),
      child: const _ManualInvoiceFormView(),
    );
  }
}

class _ManualInvoiceFormView extends StatefulWidget {
  const _ManualInvoiceFormView();

  @override
  State<_ManualInvoiceFormView> createState() => _ManualInvoiceFormViewState();
}

class _ManualInvoiceFormViewState extends State<_ManualInvoiceFormView> {
  final _formKey = GlobalKey<FormState>();
  final _studentCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMethod = 'upfront';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _studentCtrl.dispose();
    _batchCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'student_name': _studentCtrl.text.trim(),
        'batch_code': _batchCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text.trim()),
        'payment_method': _paymentMethod,
        'due_date': _dueDate.toIso8601String(),
      };
      if (_notesCtrl.text.trim().isNotEmpty) {
        data['notes'] = _notesCtrl.text.trim();
      }
      await context.read<InvoiceCubit>().createManualInvoice(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice manual berhasil dibuat'),
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
                      'Buat Invoice Manual',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Buat invoice manual untuk siswa',
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
                    controller: _studentCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Siswa wajib diisi' : null,
                    decoration: InputDecoration(
                      labelText: 'Siswa',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _batchCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Kode batch wajib diisi'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Kode Batch',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Jumlah wajib diisi';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Jumlah harus angka valid';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Jumlah (Rp)',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Metode Pembayaran',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'upfront', child: Text('Upfront')),
                      DropdownMenuItem(
                        value: 'scheduled',
                        child: Text('Cicilan'),
                      ),
                      DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                      DropdownMenuItem(
                        value: 'batch_lump',
                        child: Text('Lump Sum'),
                      ),
                      DropdownMenuItem(
                        value: 'per_session',
                        child: Text('Per Sesi'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _paymentMethod = v);
                    },
                  ),
                  const SizedBox(height: AppDimensions.md),
                  InkWell(
                    onTap: _saving ? null : _pickDueDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Jatuh Tempo',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        suffixIcon:
                            const Icon(Icons.calendar_today, size: 18),
                      ),
                      child:
                          Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Catatan (opsional)',
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
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Buat Invoice'),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/di/injection.dart';
import '../../domain/entities/coa_entity.dart';
import '../cubit/accounting_cubit.dart';

class TransactionFormPage extends StatelessWidget {
  const TransactionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountingCubit>()..loadAll(),
      child: const _TransactionFormView(),
    );
  }
}

class _TransactionFormView extends StatefulWidget {
  const _TransactionFormView();

  @override
  State<_TransactionFormView> createState() => _TransactionFormViewState();
}

class _TransactionFormViewState extends State<_TransactionFormView> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'income';
  String? _debitAccountId;
  String? _creditAccountId;
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _submit(BuildContext context, List<CoaEntity> coa) async {
    if (!_formKey.currentState!.validate()) return;
    if (_debitAccountId == null || _creditAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih akun debit dan kredit'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final amount = double.tryParse(
          _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0.0;

    final body = {
      'transaction_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'transaction_type': _transactionType,
      'debit_account_id': _debitAccountId,
      'credit_account_id': _creditAccountId,
      'amount': amount,
      'description': _descriptionCtrl.text.trim(),
      'reference_number': _referenceCtrl.text.trim(),
    };

    final cubit = context.read<AccountingCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final success = await cubit.createTransaction(body: body);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan'),
          backgroundColor: AppColors.success,
        ),
      );
      router.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan transaksi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppDimensions.lg),
          Expanded(
            child: BlocBuilder<AccountingCubit, AccountingState>(
              builder: (context, state) {
                final coa = state is AccountingLoaded ? state.coa : <CoaEntity>[];
                return _buildForm(context, coa);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input Transaksi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              'Buat transaksi keuangan baru',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, List<CoaEntity> coa) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Card(
          elevation: AppDimensions.cardElevation.toDouble(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateField(context),
                  const SizedBox(height: AppDimensions.md),
                  _buildTypeField(),
                  const SizedBox(height: AppDimensions.md),
                  _buildCoaDropdown(
                    label: 'Akun Debit',
                    value: _debitAccountId,
                    coa: coa,
                    onChanged: (v) => setState(() => _debitAccountId = v),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildCoaDropdown(
                    label: 'Akun Kredit',
                    value: _creditAccountId,
                    coa: coa,
                    onChanged: (v) => setState(() => _creditAccountId = v),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildTextField(
                    controller: _amountCtrl,
                    label: 'Jumlah',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    required: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Jumlah wajib diisi';
                      }
                      final n = double.tryParse(
                          v.replaceAll('.', '').replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Jumlah tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildTextField(
                    controller: _descriptionCtrl,
                    label: 'Deskripsi',
                    hint: 'Keterangan transaksi',
                    required: true,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Deskripsi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildTextField(
                    controller: _referenceCtrl,
                    label: 'Referensi',
                    hint: 'Nomor invoice, kode batch, dll (opsional)',
                    required: false,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _buildActions(context, coa),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal *',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm + 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'id').format(_selectedDate),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: AppDimensions.iconSm, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipe *',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _transactionType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          ),
          items: const [
            DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
            DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
            DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _transactionType = v);
          },
        ),
      ],
    );
  }

  Widget _buildCoaDropdown({
    required String label,
    required String? value,
    required List<CoaEntity> coa,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label *',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text('Pilih $label',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          ),
          items: coa
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${c.code} — ${c.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool required,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label${required ? ' *' : ''}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 14, color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, List<CoaEntity> coa) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _submitting ? null : () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.sm,
            ),
          ),
          child: const Text('Batal'),
        ),
        const SizedBox(width: AppDimensions.sm),
        ElevatedButton(
          onPressed: _submitting ? null : () => _submit(context, coa),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.sm,
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

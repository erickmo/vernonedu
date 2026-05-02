import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/bank_account_entity.dart';

/// Form dialog for creating or editing a bank/cash account.
///
/// Returns a [BankAccountEntity] on save (with id preserved when editing),
/// or null on cancel.
class BankAccountFormDialog extends StatefulWidget {
  final BankAccountEntity? initial;
  const BankAccountFormDialog({super.key, this.initial});

  @override
  State<BankAccountFormDialog> createState() => _BankAccountFormDialogState();
}

class _BankAccountFormDialogState extends State<BankAccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _branchIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accNoCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _coaCodeCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _branchIdCtrl = TextEditingController(text: i?.branchId ?? '');
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _bankNameCtrl = TextEditingController(text: i?.bankName ?? '');
    _accNoCtrl = TextEditingController(text: i?.accountNumber ?? '');
    _balanceCtrl = TextEditingController(
      text: i == null ? '0' : i.balanceCents.toString(),
    );
    _coaCodeCtrl = TextEditingController(text: i?.coaCode ?? '');
    _isActive = i?.isActive ?? true;
  }

  @override
  void dispose() {
    _branchIdCtrl.dispose();
    _nameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNoCtrl.dispose();
    _balanceCtrl.dispose();
    _coaCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Ubah Rekening' : 'Tambah Rekening'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_branchIdCtrl, 'Branch ID', required: true),
                const SizedBox(height: AppDimensions.md),
                _field(_nameCtrl, 'Nama Rekening', required: true,
                    hint: 'misal: Kas Operasional'),
                const SizedBox(height: AppDimensions.md),
                _field(_bankNameCtrl, 'Nama Bank',
                    hint: 'misal: BCA (kosongkan untuk kas)'),
                const SizedBox(height: AppDimensions.md),
                _field(_accNoCtrl, 'Nomor Rekening'),
                const SizedBox(height: AppDimensions.md),
                _field(_balanceCtrl, 'Saldo Awal (cents)',
                    hint: 'dalam sen, misal 1000000 = Rp 10.000',
                    isNumber: true),
                const SizedBox(height: AppDimensions.md),
                _field(_coaCodeCtrl, 'Kode COA',
                    hint: 'misal: 1101'),
                const SizedBox(height: AppDimensions.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    bool required = false,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
          : null,
    );
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entity = BankAccountEntity(
      id: widget.initial?.id ?? '',
      branchId: _branchIdCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountNumber: _accNoCtrl.text.trim(),
      balanceCents: int.tryParse(_balanceCtrl.text.trim()) ?? 0,
      currency: widget.initial?.currency ?? 'IDR',
      coaCode: _coaCodeCtrl.text.trim(),
      isActive: _isActive,
    );
    Navigator.of(context).pop(entity);
  }
}

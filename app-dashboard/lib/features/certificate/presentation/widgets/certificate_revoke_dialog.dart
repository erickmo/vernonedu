import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/certificate_entity.dart';

const int _kMinReasonLength = 20;
const int _kMaxReasonLength = 500;

/// Shows the revoke dialog and resolves to the entered reason on submit,
/// or `null` if the user cancels.
Future<String?> showCertificateRevokeDialog(
  BuildContext context, {
  required CertificateEntity certificate,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CertificateRevokeDialog(certificate: certificate),
  );
}

class CertificateRevokeDialog extends StatefulWidget {
  final CertificateEntity certificate;

  const CertificateRevokeDialog({super.key, required this.certificate});

  @override
  State<CertificateRevokeDialog> createState() =>
      _CertificateRevokeDialogState();
}

class _CertificateRevokeDialogState extends State<CertificateRevokeDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final ok = _controller.text.trim().length >= _kMinReasonLength;
    if (ok != _canSubmit) {
      setState(() => _canSubmit = ok);
    }
  }

  String? _validate(String? v) {
    final value = (v ?? '').trim();
    if (value.length < _kMinReasonLength) {
      return 'Alasan minimal $_kMinReasonLength karakter';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.certificate;
    return AlertDialog(
      title: const Text('Cabut Sertifikat'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaRow(label: 'Kode', value: c.certificateCode),
              const SizedBox(height: AppDimensions.xs),
              _MetaRow(
                  label: 'Pemegang',
                  value: c.studentName.isEmpty ? c.studentId : c.studentName),
              const SizedBox(height: AppDimensions.xs),
              _MetaRow(
                  label: 'Course',
                  value: c.courseName.isEmpty ? c.courseId : c.courseName),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                key: const Key('revoke_reason_field'),
                controller: _controller,
                maxLines: 4,
                maxLength: _kMaxReasonLength,
                validator: _validate,
                decoration: const InputDecoration(
                  labelText: 'Alasan Pencabutan',
                  hintText:
                      'Tulis alasan pencabutan secara jelas (minimal 20 karakter).',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _ApprovalNote(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('revoke_submit_button'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withOpacity(0.4),
          ),
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Ajukan Pencabutan'),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              )),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
        ),
      ],
    );
  }
}

class _ApprovalNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: AppDimensions.iconSm, color: AppColors.warning),
          SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Pencabutan memerlukan persetujuan: Dept Leader → Education Leader → Director.',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

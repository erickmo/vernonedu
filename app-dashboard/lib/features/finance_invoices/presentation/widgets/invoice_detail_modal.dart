import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/invoice_detail_entity.dart';
import '../cubit/invoice_cubit.dart';

String _paymentMethodLabel(String method) {
  switch (method) {
    case 'upfront':
      return 'Upfront';
    case 'scheduled':
      return 'Cicilan';
    case 'monthly':
      return 'Bulanan';
    case 'batch_lump':
      return 'Lump Sum';
    case 'per_session':
      return 'Per Sesi';
    default:
      return method;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'overdue':
      return AppColors.error;
    case 'sent':
      return AppColors.info;
    case 'draft':
      return AppColors.textHint;
    case 'cancelled':
      return AppColors.textSecondary;
    default:
      return AppColors.textHint;
  }
}

Color _statusSurface(String status) {
  switch (status) {
    case 'paid':
      return AppColors.successSurface;
    case 'overdue':
      return AppColors.errorSurface;
    case 'sent':
      return AppColors.infoSurface;
    case 'draft':
      return AppColors.surfaceVariant;
    case 'cancelled':
      return AppColors.surfaceVariant;
    default:
      return AppColors.surfaceVariant;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Lunas';
    case 'overdue':
      return 'Jatuh Tempo';
    case 'sent':
      return 'Terkirim';
    case 'draft':
      return 'Draft';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status;
  }
}

void showInvoiceDetailModal(
  BuildContext context,
  InvoiceDetailEntity invoice,
) {
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<InvoiceCubit>(),
      child: _InvoiceDetailDialog(invoice: invoice),
    ),
  );
}

class _InvoiceDetailDialog extends StatelessWidget {
  final InvoiceDetailEntity invoice;

  const _InvoiceDetailDialog({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isOverdue = invoice.dueDate.isBefore(DateTime.now()) &&
        invoice.status != 'paid' &&
        invoice.status != 'cancelled';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
                              ),
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusSurface(invoice.status),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusCircle),
                          ),
                          child: Text(
                            _statusLabel(invoice.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(invoice.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              const Divider(),
              const SizedBox(height: AppDimensions.sm),

              // Info Grid
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoGrid(children: [
                        _InfoItem(
                          label: 'Tanggal',
                          value:
                              dateFormat.format(invoice.createdAt),
                        ),
                        _InfoItem(
                          label: 'Jatuh Tempo',
                          value: dateFormat.format(invoice.dueDate),
                          valueColor: isOverdue
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                        _InfoItem(
                          label: 'Siswa/Client',
                          value:
                              '${invoice.studentName}\n${invoice.studentContact}',
                        ),
                        _InfoItem(
                          label: 'Course Batch',
                          value:
                              '${invoice.batchCode} — ${invoice.batchName}',
                        ),
                        _InfoItem(
                          label: 'Metode Pembayaran',
                          value: _paymentMethodLabel(invoice.paymentMethod),
                        ),
                        _InfoItem(
                          label: 'Jumlah',
                          value: currencyFormat.format(invoice.amount),
                          valueBold: true,
                        ),
                        _InfoItem(
                          label: 'Sumber',
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: invoice.source == 'auto'
                                  ? AppColors.infoSurface
                                  : AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusCircle),
                            ),
                            child: Text(
                              invoice.source == 'auto' ? 'Auto' : 'Manual',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: invoice.source == 'auto'
                                    ? AppColors.info
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ),
                        if (invoice.notes != null)
                          _InfoItem(
                            label: 'Catatan',
                            value: invoice.notes!,
                          ),
                        if (invoice.cancelReason != null)
                          _InfoItem(
                            label: 'Alasan Pembatalan',
                            value: invoice.cancelReason!,
                            valueColor: AppColors.error,
                          ),
                      ]),

                      // Payment History
                      if (invoice.paymentHistory.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.md),
                        Text(
                          'Riwayat Pembayaran',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        _PaymentHistoryTable(
                          entries: invoice.paymentHistory,
                          currencyFormat: currencyFormat,
                          dateFormat: dateFormat,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.sm),
              const Divider(),
              const SizedBox(height: AppDimensions.sm),

              // Actions
              _ActionButtons(invoice: invoice),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<Widget> children;
  const _InfoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.sm,
      children: children
          .map((c) => SizedBox(width: 260, child: c))
          .toList(),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final bool valueBold;
  final Widget? valueWidget;

  const _InfoItem({
    required this.label,
    this.value,
    this.valueColor,
    this.valueBold = false,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        valueWidget ??
            Text(
              value ?? '',
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppColors.textPrimary,
                fontWeight:
                    valueBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
      ],
    );
  }
}

class _PaymentHistoryTable extends StatelessWidget {
  final List<PaymentHistoryEntry> entries;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  const _PaymentHistoryTable({
    required this.entries,
    required this.currencyFormat,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      border: TableBorder.all(color: AppColors.border, width: 1),
      children: [
        TableRow(
          decoration:
              const BoxDecoration(color: AppColors.surfaceVariant),
          children: ['Tanggal', 'Jumlah', 'Metode', 'Bukti']
              .map((h) => Padding(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ))
              .toList(),
        ),
        ...entries.map(
          (e) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Text(
                  dateFormat.format(e.paidAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Text(
                  currencyFormat.format(e.amount),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Text(
                  e.method,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: e.proofUrl != null
                    ? TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Lihat Bukti',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.info),
                        ),
                      )
                    : const Text(
                        '—',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final InvoiceDetailEntity invoice;

  const _ActionButtons({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvoiceCubit>();

    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: [
        if (invoice.status != 'paid' && invoice.status != 'cancelled')
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Tandai Lunas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: _MarkPaidDialog(invoiceId: invoice.id),
                ),
              );
            },
          ),
        if (invoice.status != 'cancelled')
          OutlinedButton.icon(
            icon: const Icon(Icons.email_outlined, size: 16),
            label: const Text('Kirim Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: const BorderSide(color: AppColors.info),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              cubit.resendInvoice(invoice.id);
            },
          ),
        if (invoice.status != 'cancelled' && invoice.status != 'paid')
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Batalkan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: _CancelDialog(invoiceId: invoice.id),
                ),
              );
            },
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.print_outlined, size: 16),
          label: const Text('Print PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Fitur cetak PDF akan segera tersedia'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MarkPaidDialog extends StatefulWidget {
  final String invoiceId;
  const _MarkPaidDialog({required this.invoiceId});

  @override
  State<_MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends State<_MarkPaidDialog> {
  DateTime _paidAt = DateTime.now();
  String _method = 'transfer';
  final _proofController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    return AlertDialog(
      title: const Text('Tandai Lunas'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal Bayar',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              subtitle: Text(
                dateFormat.format(_paidAt),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paidAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _paidAt = picked);
                  }
                },
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(
                labelText: 'Metode',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.md, vertical: AppDimensions.sm),
              ),
              items: const [
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: _proofController,
              decoration: const InputDecoration(
                labelText: 'URL Bukti Pembayaran (opsional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.md, vertical: AppDimensions.sm),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  await context.read<InvoiceCubit>().markAsPaid(
                        id: widget.invoiceId,
                        paidAt: _paidAt.toIso8601String(),
                        method: _method,
                        proofUrl: _proofController.text.trim().isEmpty
                            ? null
                            : _proofController.text.trim(),
                      );
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  final String invoiceId;
  const _CancelDialog({required this.invoiceId});

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batalkan Invoice'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan Pembatalan',
            border: OutlineInputBorder(),
            hintText: 'Masukkan alasan pembatalan...',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: _loading
              ? null
              : () async {
                  final reason = _reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Alasan pembatalan wajib diisi')),
                    );
                    return;
                  }
                  setState(() => _loading = true);
                  await context.read<InvoiceCubit>().cancelInvoice(
                        id: widget.invoiceId,
                        reason: reason,
                      );
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Batalkan Invoice'),
        ),
      ],
    );
  }
}

class CreateManualInvoiceDialog extends StatefulWidget {
  const CreateManualInvoiceDialog({super.key});

  @override
  State<CreateManualInvoiceDialog> createState() =>
      _CreateManualInvoiceDialogState();
}

class _CreateManualInvoiceDialogState
    extends State<CreateManualInvoiceDialog> {
  final _studentController = TextEditingController();
  final _batchController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'upfront';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  void dispose() {
    _studentController.dispose();
    _batchController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    return AlertDialog(
      title: const Text('Buat Invoice Manual'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _studentController,
                decoration: const InputDecoration(
                  labelText: 'Siswa',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              TextField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: 'Kode Batch',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm),
                ),
                items: const [
                  DropdownMenuItem(value: 'upfront', child: Text('Upfront')),
                  DropdownMenuItem(
                      value: 'scheduled', child: Text('Cicilan')),
                  DropdownMenuItem(
                      value: 'monthly', child: Text('Bulanan')),
                  DropdownMenuItem(
                      value: 'batch_lump', child: Text('Lump Sum')),
                  DropdownMenuItem(
                      value: 'per_session', child: Text('Per Sesi')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: AppDimensions.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jatuh Tempo',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                subtitle: Text(
                  dateFormat.format(_dueDate),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined,
                      color: AppColors.primary),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _loading
              ? null
              : () async {
                  final student = _studentController.text.trim();
                  final batch = _batchController.text.trim();
                  final amountStr = _amountController.text.trim();

                  if (student.isEmpty ||
                      batch.isEmpty ||
                      amountStr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Siswa, Kode Batch, dan Jumlah wajib diisi')),
                    );
                    return;
                  }

                  final amount = double.tryParse(amountStr);
                  if (amount == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Jumlah harus berupa angka yang valid')),
                    );
                    return;
                  }

                  setState(() => _loading = true);
                  await context.read<InvoiceCubit>().createManualInvoice({
                    'student_name': student,
                    'batch_code': batch,
                    'amount': amount,
                    'payment_method': _paymentMethod,
                    'due_date': _dueDate.toIso8601String(),
                    if (_notesController.text.trim().isNotEmpty)
                      'notes': _notesController.text.trim(),
                  });
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Buat Invoice'),
        ),
      ],
    );
  }
}

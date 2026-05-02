import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/invoice_detail_entity.dart';
import '../cubit/invoice_detail_cubit.dart';
import '../cubit/invoice_detail_state.dart';

const _statusPaid = 'paid';
const _statusSent = 'sent';
const _statusDraft = 'draft';
const _statusOverdue = 'overdue';
const _statusCancelled = 'cancelled';

Color _statusColor(String s) {
  switch (s) {
    case _statusPaid:
      return AppColors.success;
    case _statusOverdue:
      return AppColors.warning;
    case _statusSent:
      return AppColors.info;
    case _statusCancelled:
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

Color _statusSurface(String s) {
  switch (s) {
    case _statusPaid:
      return AppColors.successSurface;
    case _statusOverdue:
      return AppColors.warningSurface;
    case _statusSent:
      return AppColors.infoSurface;
    case _statusCancelled:
      return AppColors.errorSurface;
    default:
      return AppColors.surfaceVariant;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case _statusPaid:
      return 'Lunas';
    case _statusSent:
      return 'Terkirim';
    case _statusDraft:
      return 'Draft';
    case _statusOverdue:
      return 'Jatuh Tempo';
    case _statusCancelled:
      return 'Dibatalkan';
    default:
      return s;
  }
}

class InvoiceDetailPage extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<InvoiceDetailCubit>()..load(invoiceId),
      child: _InvoiceDetailView(invoiceId: invoiceId),
    );
  }
}

class _InvoiceDetailView extends StatelessWidget {
  final String invoiceId;
  const _InvoiceDetailView({required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceDetailCubit, InvoiceDetailState>(
      listener: (context, state) {
        if (state is InvoiceDetailLoaded && state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionMessage!)),
          );
        }
        if (state is InvoiceDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is InvoiceDetailLoading || state is InvoiceDetailInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InvoiceDetailError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<InvoiceDetailCubit>().load(invoiceId),
          );
        }
        final loaded = state as InvoiceDetailLoaded;
        return _DetailContent(invoice: loaded.invoice);
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.md),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final InvoiceDetailEntity invoice;
  const _DetailContent({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(invoice: invoice),
          const SizedBox(height: AppDimensions.md),
          _ActionsRow(invoice: invoice),
          const SizedBox(height: AppDimensions.lg),
          _CustomerCard(invoice: invoice),
          const SizedBox(height: AppDimensions.md),
          _InvoiceMetaCard(invoice: invoice),
          if (invoice.paymentHistory.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            _PaymentHistoryCard(invoice: invoice),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final InvoiceDetailEntity invoice;
  const _Header({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Kembali',
            onPressed: () => context.go('/finance/invoices'),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(invoice.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.xs),
            decoration: BoxDecoration(
              color: _statusSurface(invoice.status),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Text(
              _statusLabel(invoice.status),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _statusColor(invoice.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final InvoiceDetailEntity invoice;
  const _ActionsRow({required this.invoice});

  bool get _canPay =>
      invoice.status != _statusPaid && invoice.status != _statusCancelled;
  bool get _canSend =>
      invoice.status == _statusDraft || invoice.status == _statusOverdue;
  bool get _canCancel =>
      invoice.status != _statusPaid && invoice.status != _statusCancelled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Tandai Lunas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          ),
          onPressed: _canPay ? () => _confirmPay(context) : null,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.send_outlined, size: 16),
          label: const Text('Kirim Invoice'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.info,
            side: const BorderSide(color: AppColors.info),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          ),
          onPressed: _canSend ? () => _confirmSend(context) : null,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined, size: 16),
          label: const Text('Batalkan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          ),
          onPressed: _canCancel ? () => _confirmCancel(context) : null,
        ),
      ],
    );
  }

  Future<void> _confirmPay(BuildContext context) async {
    final cubit = context.read<InvoiceDetailCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Lunas'),
        content: Text(
            'Yakin menandai invoice ${invoice.invoiceNumber} sebagai lunas?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tandai Lunas'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await cubit.pay(
        paidAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        paidAmount: invoice.amount,
      );
    }
  }

  Future<void> _confirmSend(BuildContext context) async {
    final cubit = context.read<InvoiceDetailCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Invoice'),
        content: Text(
            'Kirim invoice ${invoice.invoiceNumber} ke ${invoice.studentName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await cubit.sendNow();
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<InvoiceDetailCubit>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Invoice'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan pembatalan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Tutup')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      await cubit.cancelInvoice(reason);
    }
  }
}

class _CustomerCard extends StatelessWidget {
  final InvoiceDetailEntity invoice;
  const _CustomerCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Informasi Siswa',
      children: [
        _Row(label: 'Nama', value: invoice.studentName),
        _Row(label: 'Kontak', value: invoice.studentContact),
        _Row(label: 'Batch',
            value: '${invoice.batchCode} — ${invoice.batchName}'),
        _Row(label: 'Course Type', value: invoice.courseTypeName),
      ],
    );
  }
}

class _InvoiceMetaCard extends StatelessWidget {
  final InvoiceDetailEntity invoice;
  const _InvoiceMetaCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM y', 'id_ID');
    return _SectionCard(
      title: 'Detail Invoice',
      children: [
        _Row(
            label: 'Tanggal Dibuat',
            value: dateFormat.format(invoice.createdAt)),
        _Row(
            label: 'Jatuh Tempo', value: dateFormat.format(invoice.dueDate)),
        _Row(
            label: 'Metode Pembayaran',
            value: invoice.paymentMethod),
        _Row(label: 'Sumber', value: invoice.source),
        if (invoice.notes != null && invoice.notes!.isNotEmpty)
          _Row(label: 'Catatan', value: invoice.notes!),
        if (invoice.cancelReason != null && invoice.cancelReason!.isNotEmpty)
          _Row(
              label: 'Alasan Pembatalan',
              value: invoice.cancelReason!,
              valueColor: AppColors.error),
      ],
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final InvoiceDetailEntity invoice;
  const _PaymentHistoryCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM y', 'id_ID');
    final currency = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return _SectionCard(
      title: 'Riwayat Pembayaran',
      children: invoice.paymentHistory.map((p) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
          child: Row(
            children: [
              Expanded(child: Text(dateFormat.format(p.paidAt))),
              Expanded(
                child: Text(
                  currency.format(p.amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: Text(p.method)),
              Expanded(child: Text(p.recordedBy)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimensions.sm),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

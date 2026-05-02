import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../cubit/bank_account_cubit.dart';
import '../widgets/bank_account_form_dialog.dart';

class BankAccountsPage extends StatelessWidget {
  const BankAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BankAccountCubit>()..load(),
      child: const _BankAccountsView(),
    );
  }
}

class _BankAccountsView extends StatelessWidget {
  const _BankAccountsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekening Bank/Kas'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          onPressed: () => _openForm(ctx),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
          label: const Text(
            'Tambah Rekening',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: BlocBuilder<BankAccountCubit, BankAccountState>(
          builder: (context, state) {
            if (state is BankAccountLoading || state is BankAccountInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BankAccountError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }
            if (state is BankAccountLoaded) {
              if (state.items.isEmpty) return const _EmptyView();
              return _BankAccountTable(items: state.items);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final cubit = context.read<BankAccountCubit>();
    final result = await showDialog<BankAccountEntity>(
      context: context,
      builder: (_) => const BankAccountFormDialog(),
    );
    if (result != null) {
      await cubit.create(result);
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_outlined,
              size: 48, color: AppColors.textHint),
          SizedBox(height: AppDimensions.sm),
          Text(
            'Belum ada rekening bank/kas',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BankAccountTable extends StatelessWidget {
  final List<BankAccountEntity> items;
  const _BankAccountTable({required this.items});

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.cardElevation.toDouble(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primarySurface),
          columns: const [
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('Bank')),
            DataColumn(label: Text('Nomor Rekening')),
            DataColumn(label: Text('Saldo Awal'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: items.map((acc) => _buildRow(context, acc)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, BankAccountEntity acc) {
    return DataRow(cells: [
      DataCell(Text(acc.name)),
      DataCell(Text(acc.bankName)),
      DataCell(Text(acc.accountNumber)),
      DataCell(Text(_currency.format(acc.balance))),
      DataCell(_StatusChip(isActive: acc.isActive)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Ubah',
            icon: const Icon(Icons.edit, size: AppDimensions.iconMd),
            color: AppColors.primary,
            onPressed: () => _onEdit(context, acc),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline, size: AppDimensions.iconMd),
            color: AppColors.error,
            onPressed: () => _onDelete(context, acc),
          ),
        ],
      )),
    ]);
  }

  Future<void> _onEdit(BuildContext context, BankAccountEntity acc) async {
    final cubit = context.read<BankAccountCubit>();
    final result = await showDialog<BankAccountEntity>(
      context: context,
      builder: (_) => BankAccountFormDialog(initial: acc),
    );
    if (result != null) {
      await cubit.update(result);
    }
  }

  Future<void> _onDelete(BuildContext context, BankAccountEntity acc) async {
    final cubit = context.read<BankAccountCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Rekening'),
        content: Text('Yakin ingin menonaktifkan rekening "${acc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(_).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(_).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await cubit.delete(acc.id);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? AppColors.success : AppColors.textHint,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

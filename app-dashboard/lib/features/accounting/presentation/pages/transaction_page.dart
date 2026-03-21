import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/di/injection.dart';
import '../../domain/entities/transaction_entity.dart';
import '../cubit/accounting_cubit.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountingCubit>()..loadAll(),
      child: const _TransactionView(),
    );
  }
}

class _TransactionView extends StatefulWidget {
  const _TransactionView();

  @override
  State<_TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<_TransactionView> {
  String? _filterType;
  String? _filterSource;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int _page = 0;
  static const int _perPage = 25;

  final _currencyFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<TransactionEntity> _applyFilters(List<TransactionEntity> all) {
    return all.where((t) {
      if (_filterType != null && t.transactionType != _filterType) return false;
      if (_filterSource != null) {
        final isAuto = t.status == 'auto';
        if (_filterSource == 'auto' && !isAuto) return false;
        if (_filterSource == 'manual' && isAuto) return false;
      }
      if (_dateFrom != null) {
        final d = DateTime.tryParse(t.transactionDate);
        if (d != null && d.isBefore(_dateFrom!)) return false;
      }
      if (_dateTo != null) {
        final d = DateTime.tryParse(t.transactionDate);
        if (d != null && d.isAfter(_dateTo!.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (range != null) {
      setState(() {
        _dateFrom = range.start;
        _dateTo = range.end;
        _page = 0;
      });
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
          const SizedBox(height: AppDimensions.md),
          _buildFilters(context),
          const SizedBox(height: AppDimensions.md),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaksi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              'Input & Riwayat Transaksi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () => context.push('/finance/transactions/new?mode=journal'),
          icon: const Icon(Icons.book_outlined, size: AppDimensions.iconMd),
          label: const Text('+ Jurnal Umum'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        ElevatedButton.icon(
          onPressed: () => context.push('/finance/transactions/new'),
          icon: const Icon(Icons.add, size: AppDimensions.iconMd),
          label: const Text('+ Input Transaksi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      children: [
        _FilterDropdown(
          label: 'Tipe',
          value: _filterType,
          items: const [
            DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
            DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
            DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
          ],
          onChanged: (v) => setState(() {
            _filterType = v;
            _page = 0;
          }),
        ),
        const SizedBox(width: AppDimensions.sm),
        _FilterDropdown(
          label: 'Sumber',
          value: _filterSource,
          items: const [
            DropdownMenuItem(value: 'manual', child: Text('Manual')),
            DropdownMenuItem(value: 'auto', child: Text('Auto')),
          ],
          onChanged: (v) => setState(() {
            _filterSource = v;
            _page = 0;
          }),
        ),
        const SizedBox(width: AppDimensions.sm),
        OutlinedButton.icon(
          onPressed: () => _pickDateRange(context),
          icon: const Icon(Icons.date_range, size: AppDimensions.iconSm),
          label: Text(
            _dateFrom != null && _dateTo != null
                ? '${DateFormat('dd/MM').format(_dateFrom!)} – ${DateFormat('dd/MM').format(_dateTo!)}'
                : 'Tanggal',
            style: const TextStyle(fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
          ),
        ),
        if (_filterType != null || _filterSource != null || _dateFrom != null) ...[
          const SizedBox(width: AppDimensions.sm),
          TextButton(
            onPressed: () => setState(() {
              _filterType = null;
              _filterSource = null;
              _dateFrom = null;
              _dateTo = null;
              _page = 0;
            }),
            child: const Text('Reset'),
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is AccountingLoading || state is AccountingInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AccountingError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }
        if (state is AccountingLoaded) {
          final filtered = _applyFilters(state.transactions);
          final totalPages = (filtered.length / _perPage).ceil();
          final pageItems = filtered.skip(_page * _perPage).take(_perPage).toList();
          return Column(
            children: [
              Expanded(child: _buildTable(pageItems)),
              if (totalPages > 1) _buildPagination(totalPages, filtered.length),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTable(List<TransactionEntity> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return Card(
      elevation: AppDimensions.cardElevation.toDouble(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: DataTable2(
        columnSpacing: AppDimensions.sm,
        horizontalMargin: AppDimensions.md,
        minWidth: 800,
        headingRowHeight: AppDimensions.tableHeaderHeight.toDouble(),
        dataRowHeight: AppDimensions.tableRowHeight.toDouble(),
        headingRowColor: WidgetStateProperty.all(AppColors.primarySurface),
        columns: const [
          DataColumn2(label: Text('Tanggal'), size: ColumnSize.S),
          DataColumn2(label: Text('Kode'), size: ColumnSize.S),
          DataColumn2(label: Text('Deskripsi'), size: ColumnSize.L),
          DataColumn2(label: Text('Akun'), size: ColumnSize.M),
          DataColumn2(label: Text('Debit'), numeric: true, size: ColumnSize.M),
          DataColumn2(label: Text('Kredit'), numeric: true, size: ColumnSize.M),
          DataColumn2(label: Text('Sumber'), size: ColumnSize.S),
        ],
        rows: items.map((t) {
          final date = DateTime.tryParse(t.transactionDate);
          final dateStr = date != null
              ? DateFormat('dd MMM yyyy', 'id').format(date)
              : t.transactionDate;
          final isIncome = t.transactionType == 'income';
          final isExpense = t.transactionType == 'expense';
          return DataRow2(
            cells: [
              DataCell(Text(dateStr,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
              DataCell(Text(t.referenceNumber,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary))),
              DataCell(Text(t.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis)),
              DataCell(Text(t.category,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
              DataCell(isExpense
                  ? Text(_currencyFmt.format(t.amount),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500))
                  : const Text('—',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint))),
              DataCell(isIncome
                  ? Text(_currencyFmt.format(t.amount),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500))
                  : const Text('—',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint))),
              DataCell(_SourcePill(source: t.status)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination(int totalPages, int total) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Total: $total transaksi',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppDimensions.md),
          IconButton(
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${_page + 1} / $totalPages',
              style: const TextStyle(fontSize: 13)),
          IconButton(
            onPressed: _page < totalPages - 1
                ? () => setState(() => _page++)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          isDense: true,
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String source;
  const _SourcePill({required this.source});

  @override
  Widget build(BuildContext context) {
    final isAuto = source == 'auto';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isAuto ? AppColors.infoSurface : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isAuto ? 'Auto' : 'Manual',
        style: TextStyle(
          fontSize: 11,
          color: isAuto ? AppColors.info : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/ledger_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../cubit/ledger_cubit.dart';
import '../widgets/report_filter_bar.dart';

class GeneralLedgerPage extends StatelessWidget {
  const GeneralLedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LedgerCubit>()..load(),
      child: const _LedgerView(),
    );
  }
}

class _LedgerView extends StatefulWidget {
  const _LedgerView();

  @override
  State<_LedgerView> createState() => _LedgerViewState();
}

class _LedgerViewState extends State<_LedgerView> {
  String _accountSearch = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buku Besar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Catatan detail transaksi per akun',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.md),
          BlocBuilder<LedgerCubit, LedgerState>(
            builder: (context, state) {
              return ReportFilterBar(
                initialFilter: state is LedgerLoaded
                    ? state.filter
                    : const ReportFilterEntity(),
                onFilterChanged: (filter) => context
                    .read<LedgerCubit>()
                    .load(filter: filter, accountId: _accountSearch),
                showAccountFilter: true,
                accountFilterValue: _accountSearch,
                onAccountChanged: (val) {
                  setState(() => _accountSearch = val);
                  context
                      .read<LedgerCubit>()
                      .load(accountId: val.isEmpty ? null : val);
                },
              );
            },
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: BlocBuilder<LedgerCubit, LedgerState>(
              builder: (context, state) {
                if (state is LedgerLoading || state is LedgerInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is LedgerError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppDimensions.sm),
                        Text(state.message,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: AppDimensions.md),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<LedgerCubit>().load(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is LedgerLoaded) {
                  return _LedgerContent(data: state.data);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerContent extends StatelessWidget {
  final LedgerEntity data;
  const _LedgerContent({required this.data});

  static final _dateFmt = DateFormat('dd MMM yyyy', 'id');
  static final _currFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account header
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  size: AppDimensions.iconMd, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text(
                '${data.accountCode} — ${data.accountName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        // DataTable2
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: DataTable2(
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.md,
                minWidth: 900,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                headingRowColor:
                    WidgetStateProperty.all(AppColors.surfaceVariant),
                columns: const [
                  DataColumn2(
                      label: Text('Tanggal',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      size: ColumnSize.S),
                  DataColumn2(
                      label: Text('Kode',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      size: ColumnSize.S),
                  DataColumn2(
                      label: Text('Deskripsi',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      size: ColumnSize.L),
                  DataColumn2(
                      label: Text('Ref',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      size: ColumnSize.S),
                  DataColumn2(
                      label: Text('Debit',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      size: ColumnSize.M,
                      numeric: true),
                  DataColumn2(
                      label: Text('Kredit',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      size: ColumnSize.M,
                      numeric: true),
                  DataColumn2(
                      label: Text('Saldo',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      size: ColumnSize.M,
                      numeric: true),
                ],
                rows: [
                  ...data.entries.map(
                    (entry) => DataRow2(
                      cells: [
                        DataCell(Text(_dateFmt.format(entry.date),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(entry.code,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace'))),
                        DataCell(Text(entry.description,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                        DataCell(Text(entry.ref,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary))),
                        DataCell(Text(
                          entry.debit > 0 ? _currFmt.format(entry.debit) : '—',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.success),
                        )),
                        DataCell(Text(
                          entry.credit > 0 ? _currFmt.format(entry.credit) : '—',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.error),
                        )),
                        DataCell(Text(
                          _currFmt.format(entry.balance),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        )),
                      ],
                    ),
                  ),
                  // Footer totals
                  DataRow2(
                    color: WidgetStateProperty.all(AppColors.primarySurface),
                    cells: [
                      const DataCell(SizedBox.shrink()),
                      const DataCell(SizedBox.shrink()),
                      const DataCell(Text('TOTAL',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      const DataCell(SizedBox.shrink()),
                      DataCell(Text(
                        _currFmt.format(data.totalDebit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      )),
                      DataCell(Text(
                        _currFmt.format(data.totalCredit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      )),
                      const DataCell(SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../../domain/entities/trial_balance_entity.dart';
import '../cubit/trial_balance_cubit.dart';
import '../widgets/report_filter_bar.dart';

class TrialBalancePage extends StatelessWidget {
  const TrialBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TrialBalanceCubit>()..load(),
      child: const _TrialBalanceView(),
    );
  }
}

class _TrialBalanceView extends StatelessWidget {
  const _TrialBalanceView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neraca Saldo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Daftar semua akun dengan validasi keseimbangan debit-kredit',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.md),
          BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
            builder: (context, state) {
              return ReportFilterBar(
                initialFilter: state is TrialBalanceLoaded
                    ? state.filter
                    : const ReportFilterEntity(),
                onFilterChanged: (filter) =>
                    context.read<TrialBalanceCubit>().load(filter: filter),
              );
            },
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
              builder: (context, state) {
                if (state is TrialBalanceLoading ||
                    state is TrialBalanceInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TrialBalanceError) {
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
                              context.read<TrialBalanceCubit>().load(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is TrialBalanceLoaded) {
                  return _TrialBalanceContent(data: state.data);
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

class _TrialBalanceContent extends StatelessWidget {
  final TrialBalanceEntity data;
  const _TrialBalanceContent({required this.data});

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Balance check badge
        _BalanceCheckBadge(isBalanced: data.isBalanced),
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
                minWidth: 700,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                headingRowColor:
                    WidgetStateProperty.all(AppColors.surfaceVariant),
                columns: const [
                  DataColumn2(
                    label: Text('Kode Akun',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    size: ColumnSize.S,
                  ),
                  DataColumn2(
                    label: Text('Nama Akun',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text('Debit',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    size: ColumnSize.M,
                    numeric: true,
                  ),
                  DataColumn2(
                    label: Text('Kredit',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    size: ColumnSize.M,
                    numeric: true,
                  ),
                ],
                rows: [
                  ...data.accounts.map(
                    (account) => DataRow2(
                      cells: [
                        DataCell(Text(account.code,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace'))),
                        DataCell(Text(account.name,
                            style: const TextStyle(fontSize: 13))),
                        DataCell(Text(
                          account.debit > 0
                              ? _fmt.format(account.debit)
                              : '—',
                          style: TextStyle(
                            fontSize: 13,
                            color: account.debit > 0
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        )),
                        DataCell(Text(
                          account.credit > 0
                              ? _fmt.format(account.credit)
                              : '—',
                          style: TextStyle(
                            fontSize: 13,
                            color: account.credit > 0
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        )),
                      ],
                    ),
                  ),
                  // Footer totals row
                  DataRow2(
                    color: WidgetStateProperty.all(AppColors.primarySurface),
                    cells: [
                      const DataCell(SizedBox.shrink()),
                      const DataCell(Text('TOTAL',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13))),
                      DataCell(Text(
                        _fmt.format(data.totalDebit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      )),
                      DataCell(Text(
                        _fmt.format(data.totalCredit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      )),
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

class _BalanceCheckBadge extends StatelessWidget {
  final bool isBalanced;
  const _BalanceCheckBadge({required this.isBalanced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: isBalanced ? AppColors.successSurface : AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isBalanced ? AppColors.success : AppColors.error,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBalanced ? Icons.check_circle_outline : Icons.error_outline,
            size: AppDimensions.iconMd,
            color: isBalanced ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppDimensions.xs),
          Text(
            isBalanced
                ? 'Neraca Saldo Seimbang — Total Debit = Total Kredit'
                : 'Perhatian: Total Debit ≠ Total Kredit. Periksa entri jurnal.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isBalanced ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

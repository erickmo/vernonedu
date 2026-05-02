import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '_card_shell.dart';

class AnalysisCashForecastCard extends StatelessWidget {
  final CashForecastEntity cashForecast;

  const AnalysisCashForecastCard({super.key, required this.cashForecast});

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      title: 'Proyeksi Kas',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Kas saat ini: ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                kIdrFormat.format(cashForecast.currentCash),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          if (cashForecast.months.isEmpty)
            const Text(
              'Belum ada proyeksi bulanan',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            _ForecastTable(months: cashForecast.months),
        ],
      ),
    );
  }
}

class _ForecastTable extends StatelessWidget {
  final List<CashForecastMonth> months;

  const _ForecastTable({required this.months});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceVariant),
          children: [
            _hdr('Bulan'),
            _hdr('Masuk', alignRight: true),
            _hdr('Keluar', alignRight: true),
            _hdr('Akhir', alignRight: true),
          ],
        ),
        ...months.map((m) => TableRow(
              children: [
                _cell(m.month),
                _cell(kIdrFormat.format(m.inflow), alignRight: true),
                _cell(kIdrFormat.format(m.outflow), alignRight: true),
                _cell(
                  kIdrFormat.format(m.closingCash),
                  alignRight: true,
                  bold: true,
                  color: m.closingCash < 0
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ],
            )),
      ],
    );
  }

  Widget _hdr(String t, {bool alignRight = false}) => Padding(
        padding: const EdgeInsets.all(AppDimensions.xs),
        child: Text(
          t,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _cell(String t,
          {bool alignRight = false, bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.all(AppDimensions.xs),
        child: Text(
          t,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      );
}

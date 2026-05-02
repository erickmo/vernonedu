import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '_card_shell.dart';

class AnalysisRatioCard extends StatelessWidget {
  final FinancialRatiosEntity ratios;

  const AnalysisRatioCard({super.key, required this.ratios});

  @override
  Widget build(BuildContext context) {
    final tiles = <_RatioTile>[
      _RatioTile(
        label: 'Margin Profit',
        value: formatPercent(ratios.profitMargin.current),
        trend: ratios.profitMargin.trend,
      ),
      _RatioTile(
        label: 'Rasio Beban',
        value: formatPercent(ratios.expenseRatio.current),
        trend: ratios.expenseRatio.trend,
      ),
      _RatioTile(
        label: 'Pendapatan / Siswa',
        value: kIdrFormat.format(ratios.revenuePerStudent.current),
        trend: ratios.revenuePerStudent.trend,
      ),
      _RatioTile(
        label: 'Biaya / Siswa',
        value: kIdrFormat.format(ratios.costPerStudent.current),
        trend: ratios.costPerStudent.trend,
      ),
      _RatioTile(
        label: 'Profitabilitas Batch',
        value: formatPercent(ratios.avgBatchProfitability.current),
        trend: ratios.avgBatchProfitability.trend,
      ),
      _RatioTile(
        label: 'Tingkat Penagihan',
        value: formatPercent(ratios.collectionRate.current),
        trend: ratios.collectionRate.trend,
      ),
      _RatioTile(
        label: 'DSO (hari)',
        value: kRatio2.format(ratios.daysSalesOutstanding.current),
        trend: ratios.daysSalesOutstanding.trend,
      ),
      _RatioTile(
        label: 'Pertumbuhan Pendapatan',
        value: formatPercent(ratios.revenueGrowthRate.current),
        trend: ratios.revenueGrowthRate.trend,
      ),
    ];

    return AnalysisCardShell(
      title: 'Rasio Keuangan',
      icon: Icons.percent_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth < 480 ? 2 : 4;
          return Wrap(
            spacing: AppDimensions.md,
            runSpacing: AppDimensions.md,
            children: tiles
                .map((t) => SizedBox(
                      width: (constraints.maxWidth -
                              (AppDimensions.md * (cols - 1))) /
                          cols,
                      child: t,
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _RatioTile extends StatelessWidget {
  final String label;
  final String value;
  final String trend;

  const _RatioTile({
    required this.label,
    required this.value,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final trendIcon = switch (trend) {
      'up' => Icons.arrow_upward,
      'down' => Icons.arrow_downward,
      _ => Icons.remove,
    };
    final trendColor = switch (trend) {
      'up' => AppColors.success,
      'down' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(trendIcon, size: 16, color: trendColor),
            ],
          ),
        ],
      ),
    );
  }
}

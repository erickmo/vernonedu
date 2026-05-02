import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '_card_shell.dart';

class AnalysisRevenueCard extends StatelessWidget {
  final RevenueAnalysisEntity revenue;

  const AnalysisRevenueCard({super.key, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      title: 'Pendapatan',
      icon: Icons.trending_up_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kIdrFormat.format(revenue.totalRevenue),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const Text(
            'Total pendapatan periode ini',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          if (revenue.monthlyTrend.isEmpty)
            const Text(
              'Belum ada data tren bulanan',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            Column(
              children: revenue.monthlyTrend
                  .take(6)
                  .map((m) => _MonthRow(label: m.month, value: m.total))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final String label;
  final double value;

  const _MonthRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            kIdrFormat.format(value),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

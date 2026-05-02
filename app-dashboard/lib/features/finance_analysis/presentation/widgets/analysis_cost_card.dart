import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '_card_shell.dart';

class AnalysisCostCard extends StatelessWidget {
  final CostAnalysisEntity costs;

  const AnalysisCostCard({super.key, required this.costs});

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      title: 'Biaya',
      icon: Icons.payments_outlined,
      iconColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kIdrFormat.format(costs.totalCost),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.warning,
            ),
          ),
          const Text(
            'Total biaya periode ini',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          if (costs.byCategory.isEmpty)
            const Text(
              'Belum ada rincian kategori',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            Column(
              children: costs.byCategory
                  .map((c) => _CategoryRow(category: c))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CostByCategory category;

  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              category.category,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              kIdrFormat.format(category.amount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          SizedBox(
            width: 56,
            child: Text(
              formatPercent(category.pctOfTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

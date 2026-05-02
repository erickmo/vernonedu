import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '_card_shell.dart';

class AnalysisAlertsCard extends StatelessWidget {
  final List<FinancialAlert> alerts;

  const AnalysisAlertsCard({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      title: 'Peringatan',
      icon: Icons.warning_amber_outlined,
      iconColor: AppColors.warning,
      child: alerts.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
              child: Text(
                'Tidak ada peringatan saat ini',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          : Column(
              children: alerts.map((a) => _AlertRow(alert: a)).toList(),
            ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final FinancialAlert alert;

  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.level) {
      'critical' => AppColors.error,
      'warning' => AppColors.warning,
      'success' => AppColors.success,
      _ => AppColors.info,
    };
    final icon = switch (alert.level) {
      'critical' => Icons.error_outline,
      'warning' => Icons.warning_amber_outlined,
      'success' => Icons.check_circle_outline,
      _ => Icons.info_outline,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (alert.code.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      alert.code,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Currency formatter for IDR. 0 decimals.
final NumberFormat kIdrFormat =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// Number formatter — 2 decimals (used for ratios).
final NumberFormat kRatio2 = NumberFormat('#,##0.00', 'id_ID');

/// Format percentage with 1 decimal + %.
String formatPercent(double v) =>
    '${NumberFormat('#,##0.0', 'id_ID').format(v)}%';

/// Reusable Material Card shell with title and content. Always full-width.
class AnalysisCardShell extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  const AnalysisCardShell({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
                  const SizedBox(width: AppDimensions.sm),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            child,
          ],
        ),
      ),
    );
  }
}

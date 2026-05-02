import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '_card_shell.dart';

class AnalysisSuggestionsCard extends StatelessWidget {
  final List<FinancialSuggestion> suggestions;

  const AnalysisSuggestionsCard({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      title: 'Saran',
      icon: Icons.lightbulb_outline,
      iconColor: AppColors.info,
      child: suggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
              child: Text(
                'Tidak ada saran saat ini',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          : Column(
              children:
                  suggestions.map((s) => _SuggestionRow(item: s)).toList(),
            ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final FinancialSuggestion item;

  const _SuggestionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.icon.isEmpty ? '💡' : item.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.detail,
                      style: const TextStyle(
                        fontSize: 12,
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

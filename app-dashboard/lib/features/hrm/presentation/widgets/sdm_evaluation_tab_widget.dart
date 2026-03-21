import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Tab catatan evaluasi SDM.
class SdmEvaluationTabWidget extends StatelessWidget {
  final List<SdmEvaluationEntity> evaluations;

  const SdmEvaluationTabWidget({super.key, required this.evaluations});

  @override
  Widget build(BuildContext context) {
    if (evaluations.isEmpty) {
      return _buildEmpty(context);
    }
    final avgScore = evaluations.fold<double>(0, (s, e) => s + e.score) /
        evaluations.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreSummary(context, avgScore),
          const SizedBox(height: AppDimensions.lg),
          ...evaluations
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.md),
                    child: _buildEvaluationCard(context, e),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildScoreSummary(BuildContext context, double avgScore) => Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildCircleScore(context, avgScore),
            const SizedBox(width: AppDimensions.lg),
            Expanded(child: _buildScoreBreakdown(context)),
          ],
        ),
      );

  Widget _buildCircleScore(BuildContext context, double score) => Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _scoreColor(score).withOpacity(0.1),
              border: Border.all(color: _scoreColor(score), width: 3),
            ),
            child: Center(
              child: Text(
                score.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(score),
                    ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            AppStrings.sdmEvalAvgScore,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      );

  Widget _buildScoreBreakdown(BuildContext context) {
    final categories = <String, List<double>>{};
    for (final e in evaluations) {
      categories.putIfAbsent(e.category, () => []).add(e.score);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((entry) {
        final avg = entry.value.fold<double>(0, (s, v) => s + v) /
            entry.value.length;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.xs),
          child: _buildCategoryBar(context, entry.key, avg),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryBar(
    BuildContext context,
    String category,
    double avg,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                avg.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _scoreColor(avg),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: avg / 10,
            backgroundColor: AppColors.border,
            color: _scoreColor(avg),
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
        ],
      );

  Widget _buildEvaluationCard(
    BuildContext context,
    SdmEvaluationEntity eval,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEvalHeader(context, eval),
            const SizedBox(height: AppDimensions.sm),
            Text(
              eval.notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            if (eval.tags.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.sm),
              _buildTagsWrap(context, eval.tags),
            ],
          ],
        ),
      );

  Widget _buildEvalHeader(BuildContext context, SdmEvaluationEntity eval) =>
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _scoreColor(eval.score).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                eval.score.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(eval.score),
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryBadge(context, eval.category),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      '· ${eval.evaluator}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                Text(
                  _fmtDate(eval.date),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildCategoryBadge(BuildContext context, String category) =>
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(
          category,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  Widget _buildTagsWrap(BuildContext context, List<String> tags) => Wrap(
        spacing: AppDimensions.xs,
        runSpacing: AppDimensions.xs,
        children: tags
            .map((t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircle),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '#$t',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ))
            .toList(),
      );

  Widget _buildEmpty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                AppStrings.sdmNoEvaluationData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );

  Color _scoreColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return AppColors.warning;
    return AppColors.error;
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

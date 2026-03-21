import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Halaman detail misi dengan langkah-langkah.
class QuestDetailPage extends StatefulWidget {
  final String questId;

  const QuestDetailPage({super.key, required this.questId});

  @override
  State<QuestDetailPage> createState() => _QuestDetailPageState();
}

class _QuestDetailPageState extends State<QuestDetailPage> {
  final Set<int> _completedSteps = {};
  bool _showCelebration = false;

  static const _mockSteps = [
    'Pilih buku favoritmu',
    'Cari tempat yang nyaman untuk membaca',
    'Baca selama minimal 15 menit',
    'Ceritakan isi buku ke orang tua atau teman',
  ];

  double get _progress => _completedSteps.length / _mockSteps.length;
  bool get _allDone => _completedSteps.length == _mockSteps.length;

  void _toggleStep(int index) {
    setState(() {
      if (_completedSteps.contains(index)) {
        _completedSteps.remove(index);
      } else {
        _completedSteps.add(index);
      }
    });
  }

  void _complete() {
    setState(() => _showCelebration = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar dengan gradient
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.funPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text('📚', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title & Points
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Baca Buku 15 Menit',
                            style: AppTextStyles.headingL,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusCircle,
                            ),
                          ),
                          child: Text(
                            '⭐ 10 poin',
                            style: AppTextStyles.labelL.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spacingS),

                    Text(
                      'Pilih buku favoritmu dan baca minimal 15 menit hari ini! Membiasakan membaca membuatmu semakin pintar.',
                      style: AppTextStyles.bodyL,
                    ),

                    const SizedBox(height: AppDimensions.spacingL),

                    // Progress
                    Row(
                      children: [
                        Text(
                          'Progress Misi',
                          style: AppTextStyles.headingS,
                        ),
                        const Spacer(),
                        Text(
                          '${_completedSteps.length}/${_mockSteps.length} langkah',
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spacingS),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusCircle,
                      ),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacingL),

                    // Steps
                    Text('Langkah-langkah', style: AppTextStyles.headingS),

                    const SizedBox(height: AppDimensions.spacingS),

                    ..._mockSteps.asMap().entries.map(
                      (e) => _StepTile(
                        index: e.key + 1,
                        text: e.value,
                        isCompleted: _completedSteps.contains(e.key),
                        onTap: () => _toggleStep(e.key),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacingXXL),
                  ]),
                ),
              ),
            ],
          ),

          // Complete button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _allDone && !_showCelebration ? _complete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _allDone ? AppColors.accent : AppColors.divider,
                ),
                child: Text(
                  _allDone
                      ? AppStrings.completeQuest
                      : 'Selesaikan semua langkah dulu!',
                  style: AppTextStyles.buttonL,
                ),
              ),
            ),
          ),

          // Celebration overlay
          if (_showCelebration) _buildCelebration(context),
        ],
      ),
    );
  }

  Widget _buildCelebration(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppDimensions.spacingXL),
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              const SizedBox(height: AppDimensions.spacingM),
              Text(AppStrings.questCompleted, style: AppTextStyles.displayMedium),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                'Kamu mendapatkan\n⭐ 10 poin  +  ⚡ 20 XP',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingM.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.done, style: AppTextStyles.buttonL),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isCompleted;
  final VoidCallback onTap;

  const _StepTile({
    required this.index,
    required this.text,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.accent.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: isCompleted ? AppColors.accent : AppColors.divider,
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.accent : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : Text(
                        '$index',
                        style: AppTextStyles.labelL.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyL.copyWith(
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

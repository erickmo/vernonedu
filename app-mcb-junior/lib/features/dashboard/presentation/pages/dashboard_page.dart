import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';

/// Dashboard utama — tampilan ringkasan anak.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spacingM),
              _buildHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildXpCard(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildStatsRow(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildSectionTitle(AppStrings.todayMission),
              const SizedBox(height: AppDimensions.spacingS),
              _buildTodayQuests(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildSectionTitle(AppStrings.dailyHabits),
              const SizedBox(height: AppDimensions.spacingS),
              _buildTodayHabits(),
              const SizedBox(height: AppDimensions.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppDateUtils.greeting()},',
                style: AppTextStyles.bodyL,
              ),
              Text(
                'Pahlawan Kecil! 👋',
                style: AppTextStyles.headingL,
              ),
            ],
          ),
        ),
        // Avatar
        Container(
          width: AppDimensions.avatarL,
          height: AppDimensions.avatarL,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Center(child: Text('🦸', style: TextStyle(fontSize: 32))),
        ),
      ],
    );
  }

  Widget _buildXpCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.funPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'Level 5 — Pejuang',
                style: AppTextStyles.labelL.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '750 / 1000 XP',
                style: AppTextStyles.labelM.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              _buildXpStat('1,250', AppStrings.myPoints),
              const SizedBox(width: AppDimensions.spacingXL),
              _buildXpStat('7', '🔥 Streak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.headingL.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTextStyles.labelS.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            emoji: '✅',
            value: '12',
            label: 'Misi Selesai',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: _buildStatCard(
            emoji: '❤️',
            value: '5',
            label: 'Kebiasaan',
            color: AppColors.funPink,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: _buildStatCard(
            emoji: '🏆',
            value: '#3',
            label: 'Ranking',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            value,
            style: AppTextStyles.headingM.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.labelS,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.headingM);
  }

  Widget _buildTodayQuests() {
    final quests = [
      ('📚', 'Baca Buku 15 Menit', '10 poin', false),
      ('🧮', 'Latihan Matematika', '15 poin', true),
      ('🌱', 'Menyiram Tanaman', '8 poin', false),
    ];

    return Column(
      children: quests
          .map(
            (q) => _QuestTile(
              emoji: q.$1,
              title: q.$2,
              points: q.$3,
              isCompleted: q.$4,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTodayHabits() {
    final habits = [
      ('🦷', 'Sikat Gigi Pagi', true),
      ('🛏️', 'Rapikan Tempat Tidur', false),
      ('🍎', 'Makan Buah', false),
    ];

    return Row(
      children: habits
          .map(
            (h) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingXS,
                ),
                child: _HabitChip(
                  emoji: h.$1,
                  label: h.$2,
                  isChecked: h.$3,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String points;
  final bool isCompleted;

  const _QuestTile({
    required this.emoji,
    required this.title,
    required this.points,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.accent.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isCompleted
              ? AppColors.accent.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelL.copyWith(
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  points,
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isCompleted ? AppColors.accent : AppColors.divider,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isChecked;

  const _HabitChip({
    required this.emoji,
    required this.label,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spacingM,
        horizontal: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: isChecked
            ? AppColors.accent.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color:
              isChecked ? AppColors.accent : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            label,
            style: AppTextStyles.labelS,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isChecked ? AppColors.accent : AppColors.textHint,
            size: 18,
          ),
        ],
      ),
    );
  }
}

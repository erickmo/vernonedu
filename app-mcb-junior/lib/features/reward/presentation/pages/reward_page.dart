import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Halaman katalog hadiah yang bisa ditukar.
class RewardPage extends StatelessWidget {
  const RewardPage({super.key});

  static const _mockRewards = [
    (
      emoji: '🎮',
      title: 'Main Game 30 Menit Extra',
      points: 50,
      category: 'Hak Istimewa',
      color: AppColors.funPurple,
    ),
    (
      emoji: '🍦',
      title: 'Es Krim Pilihan Sendiri',
      points: 80,
      category: 'Hadiah',
      color: AppColors.funPink,
    ),
    (
      emoji: '📱',
      title: 'Video Call Bareng Teman',
      points: 30,
      category: 'Pengalaman',
      color: AppColors.funTeal,
    ),
    (
      emoji: '🎨',
      title: 'Set Krayon Baru',
      points: 120,
      category: 'Hadiah',
      color: AppColors.funOrange,
    ),
    (
      emoji: '🌟',
      title: 'Badge Super Hero Digital',
      points: 40,
      category: 'Digital',
      color: AppColors.secondary,
    ),
    (
      emoji: '🎪',
      title: 'Piknik Keluarga',
      points: 200,
      category: 'Pengalaman',
      color: AppColors.accent,
    ),
  ];

  static const _userPoints = 1250;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(AppStrings.myRewards, style: AppTextStyles.headingL),
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildPointsBanner(),
                  const SizedBox(height: AppDimensions.spacingL),
                  Text(AppStrings.rewards, style: AppTextStyles.headingM),
                  const SizedBox(height: AppDimensions.spacingS),
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimensions.spacingS,
                  crossAxisSpacing: AppDimensions.spacingS,
                  childAspectRatio: 0.85,
                ),
                itemCount: _mockRewards.length,
                itemBuilder: (context, i) => _RewardCard(
                  emoji: _mockRewards[i].emoji,
                  title: _mockRewards[i].title,
                  points: _mockRewards[i].points,
                  category: _mockRewards[i].category,
                  color: _mockRewards[i].color,
                  canAfford: _userPoints >= _mockRewards[i].points,
                  onRedeem: () => _confirmRedeem(
                    context,
                    _mockRewards[i].title,
                    _mockRewards[i].points,
                  ),
                ),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppDimensions.spacingXXL),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 48)),
          const SizedBox(width: AppDimensions.spacingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_userPoints',
                style: AppTextStyles.pointsLarge.copyWith(color: Colors.white),
              ),
              Text(
                AppStrings.myPoints,
                style: AppTextStyles.labelM.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRedeem(
      BuildContext context, String rewardTitle, int points) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: const Text('🎁 Tukar Hadiah?'),
        content: Text(
          'Kamu akan menukar $points poin untuk mendapatkan:\n\n"$rewardTitle"\n\nLanjutkan?',
          style: AppTextStyles.bodyL,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.rewardRedeemed),
                  backgroundColor: AppColors.accent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: Text(AppStrings.redeemReward, style: AppTextStyles.buttonM),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String emoji;
  final String title;
  final int points;
  final String category;
  final Color color;
  final bool canAfford;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.emoji,
    required this.title,
    required this.points,
    required this.category,
    required this.color,
    required this.canAfford,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emoji area
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusL),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 44)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: AppTextStyles.labelS.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.labelM,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                GestureDetector(
                  onTap: canAfford ? onRedeem : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? AppColors.secondary
                          : AppColors.divider,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 2),
                        Text(
                          '$points',
                          style: AppTextStyles.buttonM.copyWith(
                            color: canAfford
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
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

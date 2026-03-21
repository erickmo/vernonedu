import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';

/// Halaman profil anak.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.remove(AppConstants.accessTokenKey);
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingXL),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.funPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Center(
                        child: Text('🦸', style: TextStyle(fontSize: 52)),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Text(
                      'Anak Hebat',
                      style: AppTextStyles.headingL
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      '@pahlawan_kecil',
                      style: AppTextStyles.bodyM
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingM,
                        vertical: AppDimensions.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusCircle),
                      ),
                      child: Text(
                        '⚡ Level 5 — Pejuang',
                        style: AppTextStyles.labelL
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Row(
                  children: [
                    _buildStatBox('1,250', '⭐ Poin'),
                    _buildStatBox('12', '✅ Misi'),
                    _buildStatBox('7', '🔥 Streak'),
                    _buildStatBox('5', '❤️ Habit'),
                  ],
                ),
              ),

              // Achievements
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lencana Prestasi', style: AppTextStyles.headingM),
                    const SizedBox(height: AppDimensions.spacingS),
                    _buildAchievementRow(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Menu items
                    _buildMenuItem(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profil',
                      color: AppColors.primary,
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications_rounded,
                      label: 'Notifikasi',
                      color: AppColors.funOrange,
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Bantuan',
                      color: AppColors.funTeal,
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      label: AppStrings.logout,
                      color: AppColors.error,
                      onTap: () => _logout(context),
                      isDanger: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headingM.copyWith(color: AppColors.primary),
            ),
            Text(label, style: AppTextStyles.labelS, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementRow() {
    final badges = [
      ('🌟', '7 Hari Streak'),
      ('📚', 'Pembaca Rajin'),
      ('💪', 'Penolong Hebat'),
      ('🏃', 'Aktif Terus'),
    ];
    return Row(
      children: badges
          .map(
            (b) => Expanded(
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(b.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 2),
                    Text(
                      b.$2,
                      style: AppTextStyles.labelS,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelL.copyWith(
                  color: isDanger ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

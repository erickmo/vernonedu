import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.name : '';
        final email = state is AuthAuthenticated ? state.email : '';
        final studentCode = state is AuthAuthenticated ? state.studentCode : '';
        final initials = state is AuthAuthenticated ? state.initials : '?';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text(AppStrings.profileTitle),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(context, name, email, studentCode, initials),
                _buildStatsRow(context),
                const SizedBox(height: AppDimensions.md),
                _buildInfoSection(context, email, studentCode),
                const SizedBox(height: AppDimensions.md),
                _buildHistorySection(context),
                const SizedBox(height: AppDimensions.md),
                _buildLogoutButton(context),
                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String email,
    String studentCode,
    String initials,
  ) =>
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientPrimary,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.lg,
          AppDimensions.pagePadding,
          AppDimensions.xl + 16,
        ),
        child: Column(
          children: [
            Container(
              width: AppDimensions.avatarLg,
              height: AppDimensions.avatarLg,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: AppDimensions.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              ),
              child: Text(
                studentCode,
                style: const TextStyle(fontSize: 13, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      );

  Widget _buildStatsRow(BuildContext context) => Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: const [
              BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              _buildStat('7', 'Total Kelas', AppColors.primary),
              _buildStatDivider(),
              _buildStat('5', 'Selesai', AppColors.success),
              _buildStatDivider(),
              _buildStat('3', 'Sertifikat', const Color(0xFFE65100)),
            ],
          ),
        ),
      );

  Widget _buildStat(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _buildStatDivider() => Container(width: 1, height: 36, color: AppColors.divider);

  Widget _buildInfoSection(BuildContext context, String email, String studentCode) => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text('Informasi Akun', style: Theme.of(context).textTheme.titleSmall),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _buildInfoTile(Icons.email_outlined, 'Email', email),
            _buildInfoTile(Icons.badge_outlined, AppStrings.studentCode, studentCode),
            _buildInfoTile(Icons.business_outlined, AppStrings.department, 'Kewirausahaan'),
            _buildInfoTile(Icons.calendar_today_outlined, AppStrings.joinedDate, '1 Januari 2024'),
          ],
        ),
      );

  Widget _buildInfoTile(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildHistorySection(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text('Riwayat Belajar', style: Theme.of(context).textTheme.titleSmall),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _buildHistoryItem('Entrepreneurship Dasar', 'Selesai · Nilai: 92.5', AppColors.success, Icons.check_circle_rounded),
            _buildHistoryItem('Barbershop Profesional', 'Selesai · Nilai: 85.0', AppColors.success, Icons.check_circle_rounded),
            _buildHistoryItem('Tata Boga & Kuliner', 'Selesai · Nilai: 78.5', AppColors.success, Icons.check_circle_rounded),
            _buildHistoryItem('Digital Marketing', 'Sedang berjalan · 30%', AppColors.primary, Icons.pending_rounded),
            _buildHistoryItem('UI/UX Design', 'Sedang berjalan · 12%', AppColors.primary, Icons.pending_rounded),
          ],
        ),
      );

  Widget _buildHistoryItem(String course, String detail, Color color, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm + 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildLogoutButton(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
          label: const Text(AppStrings.logout, style: TextStyle(fontSize: 15, color: AppColors.error)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        ),
      );

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            ),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}

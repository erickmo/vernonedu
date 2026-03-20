import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Data model bisnis yang siap di-launch.
class LaunchpadBusiness {
  final String id;
  final String name;
  final int currentStep;
  final int totalSteps;
  final DateTime createdAt;

  const LaunchpadBusiness({
    required this.id,
    required this.name,
    required this.currentStep,
    required this.totalSteps,
    required this.createdAt,
  });

  double get progress =>
      totalSteps > 0 ? currentStep / totalSteps : 0.0;

  bool get isLaunched => currentStep >= totalSteps;
}

/// Launchpad page — daftar bisnis yang sudah selesai ideation
/// dan siap untuk proses launching.
class LaunchpadPage extends StatelessWidget {
  const LaunchpadPage({super.key});

  // TODO: replace with Cubit state
  static final _businesses = [
    LaunchpadBusiness(
      id: '1',
      name: 'Bisnis 001',
      currentStep: 2,
      totalSteps: 8,
      createdAt: DateTime(2026, 3, 10),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildInfoBanner(),
          const SizedBox(height: AppDimensions.spacingL),
          if (_businesses.isEmpty)
            _buildEmptyState()
          else
            _buildBusinessList(context),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Launchpad',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Eksekusi rencana bisnis kamu — dari profil hingga Go Live.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bisnis yang muncul di sini adalah bisnis yang sudah menyelesaikan semua worksheet di Business Ideation.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'Belum ada bisnis siap launch',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'Selesaikan semua worksheet di Business Ideation\nuntuk memulai proses launching.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessList(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.spacingM,
        crossAxisSpacing: AppDimensions.spacingM,
        childAspectRatio: isDesktop ? 1.8 : (isTablet ? 1.6 : 2.2),
      ),
      itemCount: _businesses.length,
      itemBuilder: (context, index) {
        final biz = _businesses[index];
        return _buildBusinessCard(context, biz);
      },
    );
  }

  Widget _buildBusinessCard(BuildContext context, LaunchpadBusiness biz) {
    return InkWell(
      onTap: () => context.go('/launchpad/${biz.id}'),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    biz.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (biz.isLaunched)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      'LAUNCHED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'Step ${biz.currentStep} of ${biz.totalSteps}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(biz.progress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: LinearProgressIndicator(
                value: biz.progress,
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

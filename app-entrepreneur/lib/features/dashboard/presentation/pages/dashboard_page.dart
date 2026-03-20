import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/progress_card_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/announcement_widget.dart';

/// Dashboard content — stat cards, announcements, quick actions,
/// recent activity, learning progress.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: AppDimensions.spacingL),
          const AnnouncementWidget(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildStatCards(context),
          const SizedBox(height: AppDimensions.spacingL),
          const QuickActionsWidget(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Welcome back! Here\'s your business overview.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;

    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.8 : 2.5),
      children: const [
        StatCardWidget(
          icon: Icons.menu_book_rounded,
          iconColor: Color(0xFF4D2975),
          iconBgColor: Color(0x1A4D2975),
          value: '12',
          label: 'Modules Completed',
          change: '+3',
        ),
        StatCardWidget(
          icon: Icons.lightbulb_rounded,
          iconColor: Color(0xFFFF6F00),
          iconBgColor: Color(0x1AFF6F00),
          value: '5',
          label: 'Business Ideas',
          change: '+2',
        ),
        StatCardWidget(
          icon: Icons.people_rounded,
          iconColor: Color(0xFF0168FA),
          iconBgColor: Color(0x1A0168FA),
          value: '8',
          label: 'Team Members',
          change: '+1',
        ),
        StatCardWidget(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Color(0xFF10B759),
          iconBgColor: Color(0x1A10B759),
          value: 'Rp 2.5M',
          label: 'Total Revenue',
          change: '+12%',
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    if (isDesktop) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: RecentActivityWidget()),
          SizedBox(width: AppDimensions.spacingL),
          Expanded(flex: 4, child: ProgressCardWidget()),
        ],
      );
    }

    return const Column(
      children: [
        RecentActivityWidget(),
        SizedBox(height: AppDimensions.spacingL),
        ProgressCardWidget(),
      ],
    );
  }
}

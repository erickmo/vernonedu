import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/marketing_funnel_widget.dart';
import '../widgets/campaign_list_widget.dart';
import '../widgets/channel_performance_widget.dart';

/// Overview tab — stats + funnel + campaigns ringkasan + channel perf.
class MarketingOverviewTab extends StatelessWidget {
  const MarketingOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(context),
          const SizedBox(height: AppDimensions.spacingL),
          const MarketingFunnelWidget(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildBottom(context),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final cross = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: cross, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM, crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 2.2 : (isTablet ? 2.0 : 3.0),
      children: const [
        _StatCard(Icons.campaign_rounded, Color(0xFF4D2975), '6', 'Active Campaigns'),
        _StatCard(Icons.people_rounded, Color(0xFF0168FA), '1.2K', 'Total Reach'),
        _StatCard(Icons.mouse_rounded, Color(0xFF10B759), '3.8%', 'Conversion Rate'),
        _StatCard(Icons.attach_money_rounded, Color(0xFFFF6F00), 'Rp 2.1M', 'Marketing Spend'),
      ],
    );
  }

  Widget _buildBottom(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    if (isDesktop) {
      return const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 6, child: CampaignListWidget()),
        SizedBox(width: AppDimensions.spacingL),
        Expanded(flex: 4, child: ChannelPerformanceWidget()),
      ]);
    }
    return const Column(children: [
      CampaignListWidget(), SizedBox(height: AppDimensions.spacingL), ChannelPerformanceWidget(),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final Color color; final String value; final String sub;
  const _StatCard(this.icon, this.color, this.value, this.sub);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusM), border: Border.all(color: AppColors.divider.withValues(alpha: 0.5))),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
        ])),
      ]),
    );
  }
}

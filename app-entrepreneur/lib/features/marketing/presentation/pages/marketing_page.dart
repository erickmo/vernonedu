import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'marketing_overview_tab.dart';
import 'marketing_brand_tab.dart';
import 'marketing_campaign_tab.dart';
import 'marketing_content_tab.dart';
import 'marketing_analytics_tab.dart';

/// Marketing page — tab-based layout.
class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Overview'),
    Tab(text: 'Branding'),
    Tab(text: 'Campaigns'),
    Tab(text: 'Content'),
    Tab(text: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.spacingL, AppDimensions.spacingL, AppDimensions.spacingL, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Marketing & Branding', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: AppDimensions.spacingXS),
              Text('Kelola brand, campaign, content, dan performa marketing bisnis kamu.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
          child: TabBar(
            controller: _tabController,
            tabs: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MarketingOverviewTab(),
              MarketingBrandTab(),
              MarketingCampaignTab(),
              MarketingContentTab(),
              MarketingAnalyticsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../leads/presentation/cubit/lead_cubit.dart';
import '../cubit/marketing_cubit.dart';
import '../cubit/marketing_state.dart';
import 'tabs/marketing_stats_tab.dart';
import 'tabs/marketing_leads_tab.dart';
import 'tabs/marketing_social_tab.dart';
import 'tabs/marketing_classdoc_tab.dart';
import 'tabs/marketing_pr_tab.dart';
import 'tabs/marketing_referral_tab.dart';
import 'tabs/marketing_calendar_tab.dart';

class MarketingPage extends StatelessWidget {
  const MarketingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<MarketingCubit>()..loadAll()),
        BlocProvider(create: (_) => getIt<LeadCubit>()..loadLeads()),
      ],
      child: const _MarketingView(),
    );
  }
}

class _MarketingView extends StatefulWidget {
  const _MarketingView();

  @override
  State<_MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<_MarketingView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    Tab(text: 'Statistik'),
    Tab(text: 'Leads'),
    Tab(text: 'Social Media'),
    Tab(text: 'Dok. Kelas'),
    Tab(text: 'PR & Event'),
    Tab(text: 'Program Referral'),
    Tab(text: 'Kalender'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.lg,
              AppDimensions.lg,
              AppDimensions.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marketing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Kelola leads, media sosial, PR, dan program referral',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppDimensions.md),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabAlignment: TabAlignment.start,
                  tabs: _tabs,
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: BlocBuilder<MarketingCubit, MarketingState>(
              builder: (context, state) {
                if (state is MarketingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is MarketingError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppDimensions.sm),
                        Text(state.message,
                            style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: AppDimensions.sm),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary),
                          onPressed: () =>
                              context.read<MarketingCubit>().loadAll(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                return TabBarView(
                  controller: _tabController,
                  children: const [
                    MarketingStatsTab(),
                    MarketingLeadsTab(),
                    MarketingSocialTab(),
                    MarketingClassDocTab(),
                    MarketingPrTab(),
                    MarketingReferralTab(),
                    MarketingCalendarTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

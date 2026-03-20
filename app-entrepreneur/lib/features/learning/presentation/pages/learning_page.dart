import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/learning_module_card.dart';
import '../widgets/practicum_section_widget.dart';

/// Learning page — modul pembelajaran dan link praktikum ke Business Ideation.
class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  static const List<LearningModule> _modules = [
    LearningModule(
      id: 'intro-entrepreneurship',
      title: 'Introduction to Entrepreneurship',
      description: 'Dasar-dasar kewirausahaan dan mindset entrepreneur',
      icon: Icons.school_rounded,
      color: Color(0xFF4D2975),
      totalLessons: 8,
      completedLessons: 8,
      duration: '2 jam',
    ),
    LearningModule(
      id: 'business-model',
      title: 'Business Model & Strategy',
      description: 'Memahami model bisnis, value proposition, dan strategi kompetitif',
      icon: Icons.business_center_rounded,
      color: Color(0xFF0168FA),
      totalLessons: 12,
      completedLessons: 8,
      duration: '4 jam',
    ),
    LearningModule(
      id: 'market-research',
      title: 'Market Research & Analysis',
      description: 'Teknik riset pasar, segmentasi, dan analisis kompetitor',
      icon: Icons.analytics_rounded,
      color: Color(0xFF10B759),
      totalLessons: 10,
      completedLessons: 5,
      duration: '3 jam',
    ),
    LearningModule(
      id: 'financial-literacy',
      title: 'Financial Literacy',
      description: 'Dasar keuangan bisnis, cash flow, profit & loss, dan budgeting',
      icon: Icons.account_balance_rounded,
      color: Color(0xFFFF6F00),
      totalLessons: 10,
      completedLessons: 3,
      duration: '3.5 jam',
    ),
    LearningModule(
      id: 'marketing-digital',
      title: 'Digital Marketing',
      description: 'Social media marketing, content strategy, dan branding digital',
      icon: Icons.campaign_rounded,
      color: Color(0xFFDC3545),
      totalLessons: 8,
      completedLessons: 0,
      duration: '3 jam',
    ),
    LearningModule(
      id: 'leadership',
      title: 'Leadership & Team Management',
      description: 'Kepemimpinan, manajemen tim, dan komunikasi efektif',
      icon: Icons.groups_rounded,
      color: Color(0xFF1DA1F2),
      totalLessons: 6,
      completedLessons: 0,
      duration: '2 jam',
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
          _buildProgressOverview(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildModulesSection(context),
          const SizedBox(height: AppDimensions.spacingXL),
          PracticumSectionWidget(
            onStartPracticum: () => context.go('/business-ideation'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Pelajari ilmu bisnis secara terstruktur, dari teori hingga praktik.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressOverview(BuildContext context) {
    final totalLessons =
        _modules.fold<int>(0, (sum, m) => sum + m.totalLessons);
    final completedLessons =
        _modules.fold<int>(0, (sum, m) => sum + m.completedLessons);
    final progress =
        totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Learning Progress',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  '$completedLessons dari $totalLessons lessons selesai',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  '${(progress * 100).toInt()}% complete',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modul Pembelajaran',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppDimensions.spacingM,
            crossAxisSpacing: AppDimensions.spacingM,
            childAspectRatio: isDesktop ? 1.6 : (isTablet ? 1.5 : 2.0),
          ),
          itemCount: _modules.length,
          itemBuilder: (context, index) {
            return LearningModuleCard(module: _modules[index]);
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/scroll_animate_widget.dart';
import '../../../core/widgets/section_header.dart';

/// Kenapa VernonEdu — 6 feature cards dengan icon dan deskripsi.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _features = [
    _Feature(
      icon: Icons.auto_stories_rounded,
      title: 'Kurikulum Terstruktur',
      description:
          'Materi disusun oleh praktisi industri dan akademisi terbaik, dipastikan relevan dengan kebutuhan bisnis nyata.',
      color: AppColors.brandIndigo,
    ),
    _Feature(
      icon: Icons.workspace_premium_rounded,
      title: 'Instruktur Berpengalaman',
      description:
          'Belajar langsung dari pengusaha sukses dan pakar bisnis yang sudah terbukti di industri masing-masing.',
      color: AppColors.brandViolet,
    ),
    _Feature(
      icon: Icons.verified_rounded,
      title: 'Sertifikasi Resmi',
      description:
          'Raih sertifikat yang diakui oleh 100+ perusahaan mitra dan institusi pendidikan terkemuka.',
      color: AppColors.brandGreen,
    ),
    _Feature(
      icon: Icons.groups_rounded,
      title: 'Komunitas Aktif',
      description:
          'Terhubung dengan ribuan pengusaha, mentor, dan investor dalam ekosistem bisnis VernonEdu.',
      color: AppColors.brandGold,
    ),
    _Feature(
      icon: Icons.schedule_rounded,
      title: 'Belajar Fleksibel',
      description:
          'Akses kursus kapan saja, di mana saja. Sesuaikan jadwal belajar dengan rutinitas bisnis Anda.',
      color: AppColors.brandBlue,
    ),
    _Feature(
      icon: Icons.support_agent_rounded,
      title: 'Mentoring Pribadi',
      description:
          'Dapatkan sesi mentoring 1-on-1 dengan pakar untuk membahas tantangan bisnis spesifik Anda.',
      color: Color(0xFF14B8A6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final padH = Responsive.sectionPaddingH(context);
    final padV = Responsive.sectionPaddingV(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Column(
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'features_header',
            child: SectionHeader(
              badge: '✦ Keunggulan Kami',
              title: 'Kenapa Ribuan Pengusaha\nMemilih VernonEdu?',
              subtitle:
                  'Lebih dari sekedar kursus online — kami hadir sebagai ekosistem lengkap untuk pertumbuhan bisnis Anda.',
            ),
          ),

          const SizedBox(height: AppDimensions.s64),

          // Feature grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
              mainAxisSpacing: AppDimensions.s24,
              crossAxisSpacing: AppDimensions.s24,
              childAspectRatio: isMobile ? 3.5 : (isTablet ? 1.8 : 1.6),
            ),
            itemCount: _features.length,
            itemBuilder: (context, i) => _FeatureCard(
              feature: _features[i],
              index: i,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final _Feature feature;
  final int index;

  const _FeatureCard({required this.feature, required this.index});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(AppDimensions.s24),
        decoration: BoxDecoration(
          gradient: _hovered
              ? LinearGradient(
                  colors: [
                    widget.feature.color.withValues(alpha: 0.08),
                    AppColors.bgCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppDimensions.r20),
          border: Border.all(
            color: _hovered
                ? widget.feature.color.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.feature.color.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: isMobile
            ? _MobileCardContent(feature: widget.feature, hovered: _hovered)
            : _DesktopCardContent(feature: widget.feature, hovered: _hovered),
      )
          .animate(delay: (widget.index * 80).ms)
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}

class _DesktopCardContent extends StatelessWidget {
  final _Feature feature;
  final bool hovered;

  const _DesktopCardContent({required this.feature, required this.hovered});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: feature.color.withValues(alpha: hovered ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.r12),
          ),
          child: Icon(feature.icon, color: feature.color, size: 26),
        ),
        const SizedBox(height: AppDimensions.s16),
        Text(feature.title, style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.s8),
        Expanded(
          child: Text(
            feature.description,
            style: AppTextStyles.bodyS,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: AppDimensions.s12),
        AnimatedOpacity(
          opacity: hovered ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              Text(
                'Pelajari lebih lanjut',
                style: AppTextStyles.labelS.copyWith(color: feature.color),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: feature.color, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileCardContent extends StatelessWidget {
  final _Feature feature;
  final bool hovered;

  const _MobileCardContent({required this.feature, required this.hovered});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: feature.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: feature.color, size: 24),
        ),
        const SizedBox(width: AppDimensions.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(feature.title, style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(feature.description, style: AppTextStyles.bodyS, maxLines: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

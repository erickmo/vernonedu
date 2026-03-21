import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/scroll_animate_widget.dart';
import '../../../core/widgets/section_header.dart';

/// Section 4: Audience Selector — "Untuk Siapa?" tab-style.
class AudienceSelectorSection extends StatefulWidget {
  const AudienceSelectorSection({super.key});

  @override
  State<AudienceSelectorSection> createState() =>
      _AudienceSelectorSectionState();
}

class _AudienceSelectorSectionState extends State<AudienceSelectorSection> {
  int _selected = 0;

  static const _audiences = [
    _Audience(
      label: 'Untuk Individu',
      icon: Icons.person_rounded,
      headline: 'Tingkatkan Skill,\nRaih Karir Impian',
      description:
          'Kursus terstruktur dari instruktur berpengalaman. Mulai dari pemula hingga mahir di bidang yang kamu minati.',
      benefits: [
        'Akses 50+ kursus premium',
        'Sertifikat yang diakui industri',
        'Komunitas pelajar aktif',
        'Mentoring 1-on-1 tersedia',
      ],
      ctaLabel: 'Lihat Kursus',
      color: AppColors.brandPurple,
    ),
    _Audience(
      label: 'Untuk Universitas',
      icon: Icons.account_balance_rounded,
      headline: 'Kolaborasi Kurikulum\n& Sertifikasi',
      description:
          'Partnership program antara VernonEdu dan institusi pendidikan tinggi untuk menghadirkan kurikulum industri terkini.',
      benefits: [
        'Modul industri terintegrasi',
        'Sertifikasi bersama',
        'Guest lecturer dari praktisi',
        'Program magang tersertifikasi',
      ],
      ctaLabel: 'Jalin Kerjasama',
      color: AppColors.brandBlue,
    ),
    _Audience(
      label: 'Untuk Sekolah',
      icon: Icons.school_rounded,
      headline: 'Program Pendamping\nBelajar Siswa',
      description:
          'Program ekstrakurikuler dan enrichment untuk siswa SMA/SMK yang ingin mempersiapkan diri menghadapi dunia kerja.',
      benefits: [
        'Program sesuai usia siswa',
        'Modul kewirausahaan dasar',
        'Kompetisi antar sekolah',
        'Laporan perkembangan siswa',
      ],
      ctaLabel: 'Daftarkan Sekolah',
      color: AppColors.brandGreen,
    ),
    _Audience(
      label: 'Untuk Korporat',
      icon: Icons.business_center_rounded,
      headline: 'Inhouse Training\n& Talent Development',
      description:
          'Program pelatihan korporat yang disesuaikan dengan kebutuhan bisnis, budaya perusahaan, dan target karyawan Anda.',
      benefits: [
        'Kurikulum custom sesuai industri',
        'Pelatihan di lokasi atau online',
        'Laporan progress karyawan',
        'ROI training yang terukur',
      ],
      ctaLabel: 'Hubungi Kami',
      color: AppColors.brandOrange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);
    final padV = Responsive.sectionPaddingV(context);

    return Container(
      color: AppColors.bgSecondary.withValues(alpha: 0.5),
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Column(
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'audience_header',
            child: const SectionHeader(
              badge: '👥 Untuk Siapa?',
              title: 'VernonEdu untuk\nSemua Kalangan',
              subtitle:
                  'Program kami dirancang untuk memenuhi kebutuhan belajar setiap segmen.',
            ),
          ),

          const SizedBox(height: AppDimensions.s40),

          // Tab selector
          ScrollAnimateWidget(
            uniqueKey: 'audience_tabs',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _audiences.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.s8),
                    child: _AudienceTab(
                      audience: entry.value,
                      isSelected: _selected == entry.key,
                      onTap: () => setState(() => _selected = entry.key),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.s32),

          // Content panel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _AudienceContent(
              key: ValueKey(_selected),
              audience: _audiences[_selected],
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceTab extends StatefulWidget {
  final _Audience audience;
  final bool isSelected;
  final VoidCallback onTap;

  const _AudienceTab({
    required this.audience,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AudienceTab> createState() => _AudienceTabState();
}

class _AudienceTabState extends State<_AudienceTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s20,
            vertical: AppDimensions.s12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.audience.color
                : (_hovered
                    ? widget.audience.color.withValues(alpha: 0.08)
                    : AppColors.bgCard),
            borderRadius: BorderRadius.circular(AppDimensions.r12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.audience.color
                  : (_hovered
                      ? widget.audience.color.withValues(alpha: 0.3)
                      : AppColors.border),
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.audience.color.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.audience.icon,
                size: 18,
                color: widget.isSelected
                    ? Colors.white
                    : widget.audience.color,
              ),
              const SizedBox(width: AppDimensions.s8),
              Text(
                widget.audience.label,
                style: AppTextStyles.labelS.copyWith(
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceContent extends StatelessWidget {
  final _Audience audience;
  final bool isMobile;

  const _AudienceContent({
    super.key,
    required this.audience,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppDimensions.s24 : AppDimensions.s40),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        border: Border.all(
          color: audience.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: audience.color.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? _MobileAudienceContent(audience: audience)
          : _DesktopAudienceContent(audience: audience),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _DesktopAudienceContent extends StatelessWidget {
  final _Audience audience;
  const _DesktopAudienceContent({required this.audience});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: headline + description + CTA
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: audience.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(audience.icon, color: audience.color, size: 28),
              ),
              const SizedBox(height: AppDimensions.s20),
              Text(
                audience.headline,
                style: AppTextStyles.h2.copyWith(height: 1.2),
              ),
              const SizedBox(height: AppDimensions.s12),
              Text(
                audience.description,
                style: AppTextStyles.bodyL.copyWith(height: 1.6),
              ),
              const SizedBox(height: AppDimensions.s32),
              GradientButton(
                label: audience.ctaLabel,
                onTap: () => context.go(AppRouter.katalog),
                height: 52,
                horizontalPadding: 28,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(width: AppDimensions.s64),

        // Right: benefit points
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yang Kamu Dapatkan',
                style:
                    AppTextStyles.labelM.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppDimensions.s20),
              ...audience.benefits.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.s12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: audience.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: audience.color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.s12),
                      Text(e.value, style: AppTextStyles.bodyM),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileAudienceContent extends StatelessWidget {
  final _Audience audience;
  const _MobileAudienceContent({required this.audience});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: audience.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(audience.icon, color: audience.color, size: 24),
            ),
            const SizedBox(width: AppDimensions.s12),
            Expanded(
              child: Text(
                audience.headline,
                style: AppTextStyles.h3.copyWith(height: 1.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.s16),
        Text(audience.description, style: AppTextStyles.bodyM),
        const SizedBox(height: AppDimensions.s20),
        ...audience.benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.s8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: audience.color, size: 18),
                  const SizedBox(width: AppDimensions.s8),
                  Expanded(child: Text(b, style: AppTextStyles.bodyS)),
                ],
              ),
            )),
        const SizedBox(height: AppDimensions.s20),
        GradientButton(
          label: audience.ctaLabel,
          onTap: () => context.go(AppRouter.katalog),
          height: 48,
          horizontalPadding: 24,
        ),
      ],
    );
  }
}

class _Audience {
  final String label;
  final IconData icon;
  final String headline;
  final String description;
  final List<String> benefits;
  final String ctaLabel;
  final Color color;

  const _Audience({
    required this.label,
    required this.icon,
    required this.headline,
    required this.description,
    required this.benefits,
    required this.ctaLabel,
    required this.color,
  });
}

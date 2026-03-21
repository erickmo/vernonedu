import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/scroll_animate_widget.dart';
import '../../../core/widgets/section_header.dart';

/// Section 3: Program Highlights — 4 kartu program utama VernonEdu.
class ProgramHighlightsSection extends StatelessWidget {
  const ProgramHighlightsSection({super.key});

  static const _programs = [
    _Program(
      emoji: '🎯',
      title: 'Program Karir',
      tagline: 'Belajar + Magang + Karir',
      description:
          'Program intensif dari nol hingga siap kerja. Belajar, magang di perusahaan partner, dan masuk talent pool.',
      route: AppRouter.katalog,
      gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
      accentColor: Color(0xFF667EEA),
    ),
    _Program(
      emoji: '📚',
      title: 'Kursus Reguler',
      tagline: 'Kuasai Skill Baru',
      description:
          'Kursus terstruktur dengan jadwal fleksibel. Cocok untuk kamu yang ingin upgrade skill sambil bekerja.',
      route: AppRouter.katalog,
      gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
      accentColor: Color(0xFF11998E),
    ),
    _Program(
      emoji: '👤',
      title: 'Kursus Privat',
      tagline: 'Belajar Sesuai Pace-mu',
      description:
          'Sesi 1-on-1 dengan instruktur pilihan. Kurikulum disesuaikan dengan kebutuhan dan target spesifik kamu.',
      route: AppRouter.katalog,
      gradient: [Color(0xFFFC4A1A), Color(0xFFF7B733)],
      accentColor: Color(0xFFFC4A1A),
    ),
    _Program(
      emoji: '🏢',
      title: 'Inhouse Training',
      tagline: 'Pelatihan untuk Tim Anda',
      description:
          'Program pelatihan korporat yang disesuaikan dengan kebutuhan industri dan budaya perusahaan Anda.',
      route: AppRouter.katalog,
      gradient: [Color(0xFF4776E6), Color(0xFF8E54E9)],
      accentColor: Color(0xFF4776E6),
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
            uniqueKey: 'programs_header',
            child: const SectionHeader(
              badge: '🚀 Program Kami',
              title: 'Pilih Program\nYang Tepat Untukmu',
              subtitle:
                  'Dari kursus reguler hingga program karir intensif — kami punya jalur belajar untuk setiap tujuan.',
            ),
          ),

          const SizedBox(height: AppDimensions.s48),

          isMobile
              ? Column(
                  children: _programs.asMap().entries.map((e) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.s16),
                      child: _ProgramCard(program: e.value, index: e.key),
                    );
                  }).toList(),
                )
              : GridView.count(
                  crossAxisCount: isTablet ? 2 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppDimensions.s24,
                  crossAxisSpacing: AppDimensions.s24,
                  childAspectRatio: isTablet ? 1.5 : 0.85,
                  children: _programs.asMap().entries.map((e) {
                    return _ProgramCard(program: e.value, index: e.key);
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatefulWidget {
  final _Program program;
  final int index;

  const _ProgramCard({required this.program, required this.index});

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.program.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          transform: Matrix4.translationValues(0, _hovered ? -8 : 0, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.program.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.r20),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.program.accentColor.withValues(
                  alpha: _hovered ? 0.4 : 0.15,
                ),
                blurRadius: _hovered ? 40 : 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isMobile
              ? _MobileCardContent(program: widget.program, hovered: _hovered)
              : _DesktopCardContent(
                  program: widget.program, hovered: _hovered),
        ),
      ),
    )
        .animate(delay: (widget.index * 100).ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _DesktopCardContent extends StatelessWidget {
  final _Program program;
  final bool hovered;

  const _DesktopCardContent(
      {required this.program, required this.hovered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                program.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),

          const Spacer(),

          Text(
            program.title,
            style: AppTextStyles.h3OnDark.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppDimensions.s8),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              program.tagline,
              style: AppTextStyles.bodyXS.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.s12),

          Text(
            program.description,
            style: AppTextStyles.bodyS.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppDimensions.s20),

          AnimatedOpacity(
            opacity: hovered ? 1.0 : 0.6,
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Text(
                  'Lihat Program',
                  style: AppTextStyles.labelS.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCardContent extends StatelessWidget {
  final _Program program;
  final bool hovered;

  const _MobileCardContent({required this.program, required this.hovered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.s20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(program.emoji,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: AppDimensions.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title,
                  style: AppTextStyles.labelM.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  program.tagline,
                  style: AppTextStyles.bodyXS.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  program.description,
                  style: AppTextStyles.bodyXS.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _Program {
  final String emoji;
  final String title;
  final String tagline;
  final String description;
  final String route;
  final List<Color> gradient;
  final Color accentColor;

  const _Program({
    required this.emoji,
    required this.title,
    required this.tagline,
    required this.description,
    required this.route,
    required this.gradient,
    required this.accentColor,
  });
}

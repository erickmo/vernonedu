import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/public_api_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/scroll_animate_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// Section 5: Featured Courses — 6 kartu kursus dari API.
class CoursesPreviewSection extends StatelessWidget {
  const CoursesPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isMobile = Responsive.isMobile(context);
        final padH = Responsive.sectionPaddingH(context);
        final padV = Responsive.sectionPaddingV(context);

        final isLoading = state is HomeLoading || state is HomeInitial;
        final courses = state is HomeLoaded ? state.courses : <PublicCourse>[];

        return Container(
          color: AppColors.bgSecondary.withValues(alpha: 0.5),
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          child: Column(
            children: [
              ScrollAnimateWidget(
                uniqueKey: 'courses_header',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: SectionHeader(
                        badge: '📚 Kursus Populer',
                        title: 'Mulai Perjalanan\nKarirmu',
                        subtitle:
                            'Pilih dari program yang dikurasi khusus oleh instruktur berpengalaman.',
                        textAlign: TextAlign.left,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: AppDimensions.s32),
                      OutlineButton(
                        label: 'Lihat Semua →',
                        onTap: () => context.go(AppRouter.katalog),
                        height: 48,
                        horizontalPadding: 24,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.s48),

              if (isLoading)
                _CoursesLoadingSkeleton(isMobile: isMobile)
              else if (courses.isEmpty)
                _CoursesEmpty(isMobile: isMobile)
              else
                _CoursesGrid(courses: courses, isMobile: isMobile),

              if (isMobile) ...[
                const SizedBox(height: AppDimensions.s32),
                GradientButton(
                  label: 'Lihat Semua Kursus',
                  onTap: () => context.go(AppRouter.katalog),
                  height: 52,
                  horizontalPadding: 32,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  final List<PublicCourse> courses;
  final bool isMobile;

  const _CoursesGrid({required this.courses, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: courses.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.s16),
            child: _ApiCourseCard(course: e.value, index: e.key),
          );
        }).toList(),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.s24,
      crossAxisSpacing: AppDimensions.s24,
      childAspectRatio: 0.85,
      children: courses
          .take(6)
          .toList()
          .asMap()
          .entries
          .map((e) => _ApiCourseCard(course: e.value, index: e.key))
          .toList(),
    );
  }
}

class _CoursesEmpty extends StatelessWidget {
  final bool isMobile;

  const _CoursesEmpty({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return _StaticCoursesGrid(isMobile: isMobile);
  }
}

/// Fallback static cards ketika API tidak mengembalikan data.
class _StaticCoursesGrid extends StatelessWidget {
  final bool isMobile;

  const _StaticCoursesGrid({required this.isMobile});

  static const _staticCourses = [
    _StaticCourse(
      title: 'Program Karir Digital',
      type: 'Program Karir',
      priceDisplay: 'Rp 3jt',
      facilitator: 'Tim VernonEdu',
      color: Color(0xFF667EEA),
      icon: Icons.trending_up_rounded,
    ),
    _StaticCourse(
      title: 'Kursus Business Canvas',
      type: 'Kursus Reguler',
      priceDisplay: 'Rp 1.5jt',
      facilitator: 'Tim VernonEdu',
      color: Color(0xFF11998E),
      icon: Icons.grid_view_rounded,
    ),
    _StaticCourse(
      title: 'Digital Marketing Mastery',
      type: 'Kursus Reguler',
      priceDisplay: 'Rp 2jt',
      facilitator: 'Tim VernonEdu',
      color: Color(0xFFFC4A1A),
      icon: Icons.campaign_rounded,
    ),
    _StaticCourse(
      title: 'Leadership & Manajemen',
      type: 'Kursus Privat',
      priceDisplay: 'Rp 4jt',
      facilitator: 'Tim VernonEdu',
      color: Color(0xFF4776E6),
      icon: Icons.people_rounded,
    ),
    _StaticCourse(
      title: 'Keuangan Bisnis',
      type: 'Kursus Reguler',
      priceDisplay: 'Rp 1.8jt',
      facilitator: 'Tim VernonEdu',
      color: Color(0xFFF59E0B),
      icon: Icons.account_balance_wallet_rounded,
    ),
    _StaticCourse(
      title: 'Inhouse Training Custom',
      type: 'Inhouse Training',
      priceDisplay: 'Hubungi Kami',
      facilitator: 'Tim VernonEdu',
      color: Color(0xFF7C3AED),
      icon: Icons.business_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: _staticCourses.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.s16),
            child: _StaticCourseCard(course: e.value, index: e.key),
          );
        }).toList(),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.s24,
      crossAxisSpacing: AppDimensions.s24,
      childAspectRatio: 0.85,
      children: _staticCourses
          .asMap()
          .entries
          .map((e) => _StaticCourseCard(course: e.value, index: e.key))
          .toList(),
    );
  }
}

class _CoursesLoadingSkeleton extends StatelessWidget {
  final bool isMobile;

  const _CoursesLoadingSkeleton({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.s24,
      crossAxisSpacing: AppDimensions.s24,
      childAspectRatio: isMobile ? 4 : 0.85,
      children: List.generate(
        isMobile ? 3 : 6,
        (_) => _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.r20),
                topRight: Radius.circular(AppDimensions.r20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 12,
                    width: 80,
                    color: AppColors.bgSurface),
                const SizedBox(height: 12),
                Container(
                    height: 16,
                    width: double.infinity,
                    color: AppColors.bgSurface),
                const SizedBox(height: 8),
                Container(
                    height: 16, width: 200, color: AppColors.bgSurface),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.4));
  }
}

// ─── API Course Card ───────────────────────────────────────────────────────────

class _ApiCourseCard extends StatefulWidget {
  final PublicCourse course;
  final int index;

  const _ApiCourseCard({required this.course, required this.index});

  @override
  State<_ApiCourseCard> createState() => _ApiCourseCardState();
}

class _ApiCourseCardState extends State<_ApiCourseCard> {
  bool _hovered = false;

  static const _colors = [
    Color(0xFF667EEA),
    Color(0xFF11998E),
    Color(0xFFFC4A1A),
    Color(0xFF4776E6),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
  ];

  static const _icons = [
    Icons.trending_up_rounded,
    Icons.grid_view_rounded,
    Icons.campaign_rounded,
    Icons.people_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.business_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[widget.index % _colors.length];
    final icon = _icons[widget.index % _icons.length];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(AppRouter.katalog),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppDimensions.r20),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.r20),
                  topRight: Radius.circular(AppDimensions.r20),
                ),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.course.status.isNotEmpty
                            ? widget.course.status.toUpperCase()
                            : 'BUKA',
                        style: AppTextStyles.badge.copyWith(
                          color: color,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.s8),

                    Text(
                      widget.course.name,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppDimensions.s8),

                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.course.facilitatorName.isNotEmpty
                                ? widget.course.facilitatorName
                                : 'Instruktur VernonEdu',
                            style: AppTextStyles.bodyXS
                                .copyWith(color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.s12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.course.priceDisplay,
                          style: AppTextStyles.h4.copyWith(color: color),
                        ),
                        Row(
                          children: [
                            Icon(Icons.people_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.course.enrollmentCount}/${widget.course.maxParticipants}',
                              style: AppTextStyles.bodyXS
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.s12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRouter.katalog),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: AppTextStyles.labelS.copyWith(color: color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (widget.index * 80).ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ─── Static Course Card ────────────────────────────────────────────────────────

class _StaticCourseCard extends StatefulWidget {
  final _StaticCourse course;
  final int index;

  const _StaticCourseCard({required this.course, required this.index});

  @override
  State<_StaticCourseCard> createState() => _StaticCourseCardState();
}

class _StaticCourseCardState extends State<_StaticCourseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(AppRouter.katalog),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppDimensions.r20),
            border: Border.all(
              color: _hovered
                  ? widget.course.color.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.course.color.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.r20),
                  topRight: Radius.circular(AppDimensions.r20),
                ),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.course.color,
                        widget.course.color.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.course.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.course.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                widget.course.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.course.type,
                        style: AppTextStyles.badge.copyWith(
                          color: widget.course.color,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    Text(
                      widget.course.title,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          widget.course.facilitator,
                          style: AppTextStyles.bodyXS
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.course.priceDisplay,
                          style: AppTextStyles.h4
                              .copyWith(color: widget.course.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRouter.katalog),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.course.color,
                          side: BorderSide(
                              color: widget.course.color
                                  .withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: AppTextStyles.labelS
                              .copyWith(color: widget.course.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (widget.index * 80).ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _StaticCourse {
  final String title;
  final String type;
  final String priceDisplay;
  final String facilitator;
  final Color color;
  final IconData icon;

  const _StaticCourse({
    required this.title,
    required this.type,
    required this.priceDisplay,
    required this.facilitator,
    required this.color,
    required this.icon,
  });
}

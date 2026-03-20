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
import '../../kursus/data/course_data.dart';

/// Preview 3 kursus unggulan di homepage.
class CoursesPreviewSection extends StatelessWidget {
  const CoursesPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);
    final padV = Responsive.sectionPaddingV(context);
    final featuredCourses = CourseData.courses.take(3).toList();

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
                Expanded(
                  child: SectionHeader(
                    badge: '📚 Kursus Unggulan',
                    title: 'Mulai Perjalanan\nBisnis Anda',
                    subtitle:
                        'Pilih dari 50+ kursus yang dikurasi khusus untuk membantu Anda membangun bisnis yang sukses.',
                    textAlign: TextAlign.left,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: AppDimensions.s32),
                  OutlineButton(
                    label: 'Lihat Semua Kursus',
                    onTap: () => context.go(AppRouter.kursus),
                    height: 48,
                    horizontalPadding: 24,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.s48),

          // Course cards
          isMobile
              ? Column(
                  children: featuredCourses.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.s16),
                      child: _CoursePreviewCard(
                        course: entry.value,
                        index: entry.key,
                      ),
                    );
                  }).toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: featuredCourses.asMap().entries.map((entry) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: entry.key < 2 ? AppDimensions.s24 : 0,
                        ),
                        child: _CoursePreviewCard(
                          course: entry.value,
                          index: entry.key,
                        ),
                      ),
                    );
                  }).toList(),
                ),

          if (isMobile) ...[
            const SizedBox(height: AppDimensions.s32),
            GradientButton(
              label: 'Lihat Semua Kursus',
              onTap: () => context.go(AppRouter.kursus),
              height: 52,
              horizontalPadding: 32,
            ),
          ],
        ],
      ),
    );
  }
}

class _CoursePreviewCard extends StatefulWidget {
  final CourseModel course;
  final int index;

  const _CoursePreviewCard({required this.course, required this.index});

  @override
  State<_CoursePreviewCard> createState() => _CoursePreviewCardState();
}

class _CoursePreviewCardState extends State<_CoursePreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppDimensions.r20),
            border: Border.all(
              color: _hovered ? AppColors.brandIndigo.withValues(alpha: 0.4) : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.brandIndigo.withValues(alpha: 0.15),
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
              _CourseThumbnail(course: widget.course),

              Padding(
                padding: const EdgeInsets.all(AppDimensions.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    _CategoryBadge(label: widget.course.category),

                    const SizedBox(height: AppDimensions.s12),

                    // Title
                    Text(
                      widget.course.title,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppDimensions.s8),

                    // Instructor
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: widget.course.gradientColors.first,
                          child: Text(
                            widget.course.instructorInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.course.instructor,
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.s16),

                    // Stats row
                    Row(
                      children: [
                        _CourseStat(
                          icon: Icons.star_rounded,
                          label: widget.course.rating.toString(),
                          color: AppColors.brandGold,
                        ),
                        const SizedBox(width: AppDimensions.s16),
                        _CourseStat(
                          icon: Icons.people_rounded,
                          label: '${widget.course.students}+',
                        ),
                        const SizedBox(width: AppDimensions.s16),
                        _CourseStat(
                          icon: Icons.schedule_rounded,
                          label: widget.course.duration,
                        ),
                        const Spacer(),
                        _CourseLevelBadge(level: widget.course.level),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.s16),

                    // Divider
                    Container(
                      height: 1,
                      color: AppColors.border,
                    ),

                    const SizedBox(height: AppDimensions.s16),

                    // Price & CTA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.course.originalPrice != null)
                              Text(
                                widget.course.originalPrice!,
                                style: AppTextStyles.bodyXS.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            Text(
                              widget.course.price,
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.brandIndigo,
                              ),
                            ),
                          ],
                        ),
                        GradientButton(
                          label: 'Daftar',
                          onTap: () => context.go(AppRouter.kursus),
                          height: 40,
                          horizontalPadding: 20,
                          borderRadius: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: (widget.index * 100).ms)
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}

class _CourseThumbnail extends StatelessWidget {
  final CourseModel course;

  const _CourseThumbnail({required this.course});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.r20),
        topRight: Radius.circular(AppDimensions.r20),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: course.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Pattern overlay
            Positioned.fill(
              child: CustomPaint(painter: _HexPatternPainter()),
            ),
            // Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(course.icon, color: Colors.white, size: 32),
              ),
            ),
            // Badge bestseller
            if (course.isBestseller)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandGold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'BESTSELLER',
                    style: AppTextStyles.badge.copyWith(
                      color: const Color(0xFF78350F),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HexPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const hexSize = 30.0;
    for (double y = 0; y < size.height + hexSize; y += hexSize * 1.5) {
      for (double x = 0; x < size.width + hexSize; x += hexSize * 1.7) {
        _drawHex(canvas, paint, Offset(x, y), hexSize);
        _drawHex(canvas, paint, Offset(x + hexSize * 0.85, y + hexSize * 0.75), hexSize);
      }
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * 3.14159 / 180;
      final x = center.dx + size * 0.5 * (i == 0 ? 1 : 1) * _cos(angle);
      final y = center.dy + size * 0.5 * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double rad) => (rad * 180 / 3.14159 % 360) < 90 || (rad * 180 / 3.14159 % 360) > 270
      ? 1.0 - (rad * rad / 2)
      : -(1.0 - (rad * rad / 2));

  double _sin(double rad) => rad - (rad * rad * rad / 6);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryBadge extends StatelessWidget {
  final String label;

  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.brandIndigo.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: AppColors.textAccent, fontSize: 10),
      ),
    );
  }
}

class _CourseStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CourseStat({
    required this.icon,
    required this.label,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodyXS.copyWith(color: color)),
      ],
    );
  }
}

class _CourseLevelBadge extends StatelessWidget {
  final String level;

  const _CourseLevelBadge({required this.level});

  static const _colors = {
    'Pemula': AppColors.brandGreen,
    'Menengah': AppColors.brandGold,
    'Mahir': AppColors.brandRed,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[level] ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level,
        style: AppTextStyles.bodyXS.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Model data kursus dari API.
class CourseData {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? priceLabel;
  final int? totalModules;
  final String? level;

  const CourseData({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.priceLabel,
    this.totalModules,
    this.level,
  });

  factory CourseData.fromJson(Map<String, dynamic> json) {
    return CourseData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      priceLabel: json['price_label']?.toString(),
      totalModules: json['total_modules'] as int?,
      level: json['level']?.toString(),
    );
  }
}

/// Card kursus — digunakan di semua program pages.
class CourseCard extends StatefulWidget {
  final CourseData course;
  final int index;

  const CourseCard({super.key, required this.course, required this.index});

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _hovered = false;

  Color get _accentColor {
    switch (widget.course.type) {
      case 'program_karir':
        return AppColors.brandPurple;
      case 'reguler':
        return AppColors.brandBlue;
      case 'privat':
        return AppColors.brandGreen;
      case 'sertifikasi':
        return AppColors.brandGold;
      default:
        return AppColors.brandPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/katalog/${widget.course.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.s24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r20),
            border: Border.all(
              color:
                  _hovered
                      ? _accentColor.withValues(alpha: 0.5)
                      : AppColors.border,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.r999),
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _typeLabel(widget.course.type),
                  style: AppTextStyles.badge.copyWith(color: _accentColor),
                ),
              ),

              const SizedBox(height: AppDimensions.s16),

              // Title
              Text(
                widget.course.title,
                style: AppTextStyles.h4,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppDimensions.s8),

              // Description
              Text(
                widget.course.description,
                style: AppTextStyles.bodyS,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              const SizedBox(height: AppDimensions.s16),

              // Meta row
              Row(
                children: [
                  if (widget.course.totalModules != null) ...[
                    Icon(
                      Icons.menu_book_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.course.totalModules} Modul',
                      style: AppTextStyles.bodyXS,
                    ),
                    const SizedBox(width: AppDimensions.s12),
                  ],
                  if (widget.course.level != null) ...[
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(widget.course.level!, style: AppTextStyles.bodyXS),
                  ],
                  const Spacer(),
                  if (widget.course.priceLabel != null)
                    Text(
                      widget.course.priceLabel!,
                      style: AppTextStyles.labelS.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.s16),

              // CTA row
              Row(
                children: [
                  Text(
                    'Lihat Detail',
                    style: AppTextStyles.labelS.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedSlide(
                    offset: _hovered ? const Offset(0.2, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (widget.index * 80).ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, end: 0);
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'program_karir':
        return 'Program Karir';
      case 'reguler':
        return 'Kursus Reguler';
      case 'privat':
        return 'Kursus Privat';
      case 'sertifikasi':
        return 'Sertifikasi';
      default:
        return type;
    }
  }
}

/// Loading skeleton untuk course card.
class CourseCardSkeleton extends StatefulWidget {
  const CourseCardSkeleton({super.key});

  @override
  State<CourseCardSkeleton> createState() => _CourseCardSkeletonState();
}

class _CourseCardSkeletonState extends State<CourseCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final shimmerColor = AppColors.border.withValues(alpha: _shimmer.value);
        return Container(
          padding: const EdgeInsets.all(AppDimensions.s24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(w: 80, h: 24, color: shimmerColor),
              const SizedBox(height: AppDimensions.s16),
              _SkeletonBox(w: double.infinity, h: 20, color: shimmerColor),
              const SizedBox(height: 6),
              _SkeletonBox(w: 160, h: 20, color: shimmerColor),
              const SizedBox(height: AppDimensions.s12),
              _SkeletonBox(w: double.infinity, h: 14, color: shimmerColor),
              const SizedBox(height: 4),
              _SkeletonBox(w: double.infinity, h: 14, color: shimmerColor),
              const SizedBox(height: 4),
              _SkeletonBox(w: 200, h: 14, color: shimmerColor),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double w;
  final double h;
  final Color color;

  const _SkeletonBox({required this.w, required this.h, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w == double.infinity ? double.infinity : w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Grid kursus dari API dengan loading dan empty state.
class CoursesGrid extends StatelessWidget {
  final Future<List<CourseData>> future;

  const CoursesGrid({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseData>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return _buildEmptyState();
        }
        final courses = snap.data!;
        return _buildGrid(courses);
      },
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        return Wrap(
          spacing: AppDimensions.s24,
          runSpacing: AppDimensions.s24,
          children: List.generate(
            cols * 2,
            (_) => SizedBox(
              width: (constraints.maxWidth - (cols - 1) * AppDimensions.s24) / cols,
              height: 220,
              child: const CourseCardSkeleton(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s48),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.school_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimensions.s16),
          Text(
            'Kursus Segera Tersedia',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.s8),
          Text(
            'Kami sedang menyiapkan kursus terbaik untuk Anda.\nPantau terus update terbaru kami.',
            style: AppTextStyles.bodyS,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<CourseData> courses) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        final itemWidth = (constraints.maxWidth - (cols - 1) * AppDimensions.s24) / cols;
        return Wrap(
          spacing: AppDimensions.s24,
          runSpacing: AppDimensions.s24,
          children: courses.asMap().entries.map((e) {
            return SizedBox(
              width: itemWidth,
              height: 260,
              child: CourseCard(course: e.value, index: e.key),
            );
          }).toList(),
        );
      },
    );
  }
}

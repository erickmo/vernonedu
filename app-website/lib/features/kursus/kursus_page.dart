import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/navbar_widget.dart';
import '../../core/widgets/section_header.dart';
import 'data/course_data.dart';

/// Halaman daftar kursus VernonEdu.
class KursusPage extends StatefulWidget {
  const KursusPage({super.key});

  @override
  State<KursusPage> createState() => _KursusPageState();
}

class _KursusPageState extends State<KursusPage> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String _sortBy = 'Populer';

  List<CourseModel> get _filteredCourses {
    return CourseData.courses.where((c) {
      final matchCategory = _selectedCategory == 'Semua' ||
          c.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      final matchSearch = _searchQuery.isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.instructor.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);

    return WebScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          _KursusPageHeader(padH: padH),

          // Filter bar
          _FilterBar(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (c) => setState(() => _selectedCategory = c),
            searchQuery: _searchQuery,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            sortBy: _sortBy,
            onSortChanged: (s) => setState(() => _sortBy = s),
            isMobile: isMobile,
            padH: padH,
          ),

          const SizedBox(height: AppDimensions.s40),

          // Course grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH),
            child: _CourseGrid(
              courses: _filteredCourses,
              isMobile: isMobile,
            ),
          ),

          const SizedBox(height: AppDimensions.s80),

          // Footer
          const FooterWidget(),
        ],
      ),
    );
  }
}

class _KursusPageHeader extends StatelessWidget {
  final double padH;

  const _KursusPageHeader({required this.padH});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padH,
        vertical: AppDimensions.s80,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D2068), Color(0xFF5B3A9A), Color(0xFF7C68EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SectionHeader(
            badge: '📚 Semua Kursus',
            title: 'Temukan Kursus\nYang Tepat untuk Anda',
            subtitle:
                '50+ kursus premium dikurasi dari instruktur terbaik. Mulai belajar hari ini dan wujudkan bisnis impian Anda.',
            isDark: true,
          ),
          const SizedBox(height: AppDimensions.s40),
          // Hero stats
          Wrap(
            spacing: AppDimensions.s32,
            runSpacing: AppDimensions.s16,
            alignment: WrapAlignment.center,
            children: [
              _QuickStat(label: '50+ Kursus', icon: Icons.auto_stories_rounded),
              _QuickStat(label: '200+ Instruktur', icon: Icons.people_rounded),
              _QuickStat(label: 'Sertifikat Resmi', icon: Icons.verified_rounded),
              _QuickStat(label: 'Akses Seumur Hidup', icon: Icons.all_inclusive_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final IconData icon;

  const _QuickStat({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelS.copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final bool isMobile;
  final double padH;

  const _FilterBar({
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortBy,
    required this.onSortChanged,
    required this.isMobile,
    required this.padH,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  value: searchQuery,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: AppDimensions.s12),
              _SortDropdown(value: sortBy, onChanged: onSortChanged),
            ],
          ),

          const SizedBox(height: AppDimensions.s16),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CourseData.categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryChip(
                    label: cat,
                    isSelected: selectedCategory == cat,
                    onTap: () => onCategoryChanged(cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Cari kursus atau instruktur...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandIndigo, width: 2),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.bgCard,
          style: AppTextStyles.bodyS.copyWith(color: AppColors.textPrimary),
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
          items: ['Populer', 'Terbaru', 'Rating', 'Harga Terendah']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelS.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CourseGrid extends StatelessWidget {
  final List<CourseModel> courses;
  final bool isMobile;

  const _CourseGrid({required this.courses, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s80),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded,
                  color: AppColors.textMuted, size: 64),
              const SizedBox(height: 16),
              Text('Kursus tidak ditemukan',
                  style: AppTextStyles.h4.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width < 1100 ? 2 : 3),
        mainAxisSpacing: AppDimensions.s24,
        crossAxisSpacing: AppDimensions.s24,
        childAspectRatio: isMobile ? 2.2 : 0.72,
      ),
      itemCount: courses.length,
      itemBuilder: (context, i) => _FullCourseCard(course: courses[i], index: i),
    );
  }
}

class _FullCourseCard extends StatefulWidget {
  final CourseModel course;
  final int index;

  const _FullCourseCard({required this.course, required this.index});

  @override
  State<_FullCourseCard> createState() => _FullCourseCardState();
}

class _FullCourseCardState extends State<_FullCourseCard> {
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
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppDimensions.r20),
          border: Border.all(
            color: _hovered
                ? widget.course.gradientColors.first.withValues(alpha: 0.5)
                : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.course.gradientColors.first.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [],
        ),
        child: isMobile
            ? _MobileCourseCard(course: widget.course)
            : _DesktopCourseCardContent(course: widget.course),
      )
          .animate(delay: (widget.index * 80).ms)
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.15, end: 0),
    );
  }
}

class _DesktopCourseCardContent extends StatelessWidget {
  final CourseModel course;

  const _DesktopCourseCardContent({required this.course});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                colors: course.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(course.icon, color: Colors.white.withValues(alpha: 0.4), size: 64),
                ),
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
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: course.gradientColors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: course.gradientColors.first.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    course.category,
                    style: AppTextStyles.badge.copyWith(
                      color: course.gradientColors.first,
                      fontSize: 9,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  course.title,
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  course.instructor,
                  style: AppTextStyles.bodyXS.copyWith(color: AppColors.textMuted),
                ),

                const Spacer(),

                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.brandGold, size: 12),
                    const SizedBox(width: 3),
                    Text(course.rating.toString(),
                        style: AppTextStyles.bodyXS.copyWith(color: AppColors.brandGold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.textMuted, size: 12),
                    const SizedBox(width: 3),
                    Text(course.duration, style: AppTextStyles.bodyXS),
                    const Spacer(),
                    _LevelPill(level: course.level),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course.originalPrice != null)
                          Text(
                            course.originalPrice!,
                            style: AppTextStyles.bodyXS.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textMuted,
                            ),
                          ),
                        Text(
                          course.price,
                          style: AppTextStyles.labelM.copyWith(
                            color: AppColors.brandIndigo,
                          ),
                        ),
                      ],
                    ),
                    GradientButton(
                      label: 'Daftar',
                      onTap: () {},
                      height: 36,
                      horizontalPadding: 16,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileCourseCard extends StatelessWidget {
  final CourseModel course;

  const _MobileCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Thumbnail
        Container(
          width: 80,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: course.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.r20),
              bottomLeft: Radius.circular(AppDimensions.r20),
            ),
          ),
          child: Center(
            child: Icon(course.icon, color: Colors.white.withValues(alpha: 0.6), size: 32),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(course.title, style: AppTextStyles.labelM, maxLines: 2),
                const SizedBox(height: 4),
                Text(course.instructor, style: AppTextStyles.bodyXS),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.brandGold, size: 12),
                    Text(' ${course.rating}',
                        style: AppTextStyles.bodyXS.copyWith(color: AppColors.brandGold)),
                    const SizedBox(width: 12),
                    Text(course.duration, style: AppTextStyles.bodyXS),
                    const Spacer(),
                    Text(course.price,
                        style: AppTextStyles.labelS.copyWith(color: AppColors.brandIndigo)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  final String level;

  const _LevelPill({required this.level});

  static const _colors = {
    'Pemula': AppColors.brandGreen,
    'Menengah': AppColors.brandGold,
    'Mahir': AppColors.brandRed,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[level] ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level,
        style: AppTextStyles.bodyXS.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Course page — daftar mata pelajaran dalam bentuk grid card.
class CoursePage extends StatelessWidget {
  const CoursePage({super.key});

  static const List<_CourseData> _courses = [
    _CourseData(
      icon: Icons.calculate_rounded,
      iconColor: Color(0xFF4D2975),
      iconBgColor: Color(0x1A4D2975),
      title: 'Matematika',
      description: 'Aljabar, geometri, dan statistika dasar',
      studentCount: 32,
    ),
    _CourseData(
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF0168FA),
      iconBgColor: Color(0x1A0168FA),
      title: 'Bahasa Indonesia',
      description: 'Tata bahasa, sastra, dan komunikasi efektif',
      studentCount: 28,
    ),
    _CourseData(
      icon: Icons.science_rounded,
      iconColor: Color(0xFF10B759),
      iconBgColor: Color(0x1A10B759),
      title: 'IPA',
      description: 'Fisika, kimia, dan biologi terapan',
      studentCount: 30,
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
          _buildCourseGrid(context),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Kelola mata pelajaran',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseGrid(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppDimensions.breakpointDesktop;
    final isTablet = width >= AppDimensions.breakpointMobile;

    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 1.6 : (isTablet ? 1.4 : 2.2),
      children: _courses.map((course) => _CourseCard(data: course)).toList(),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.data});

  final _CourseData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconBadge(),
              _buildStudentBadge(),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            data.title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Expanded(
            child: Text(
              data.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      width: AppDimensions.avatarM,
      height: AppDimensions.avatarM,
      decoration: BoxDecoration(
        color: data.iconBgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Icon(
        data.icon,
        color: data.iconColor,
        size: AppDimensions.iconM,
      ),
    );
  }

  Widget _buildStudentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_rounded,
            size: AppDimensions.iconS,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            '${data.studentCount} siswa',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseData {
  const _CourseData({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.studentCount,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final int studentCount;
}

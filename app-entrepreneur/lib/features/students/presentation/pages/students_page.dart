import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Students page — placeholder list of students with avatar, name, and
/// active-status badge. Follows the same layout convention as DashboardPage.
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  // ---------------------------------------------------------------------------
  // Dummy data
  // ---------------------------------------------------------------------------
  static const List<_StudentData> _students = [
    _StudentData(
      name: 'Andi Pratama',
      studentClass: 'Kelas XI — Bisnis A',
      initials: 'AP',
      isActive: true,
    ),
    _StudentData(
      name: 'Budi Santoso',
      studentClass: 'Kelas X — Bisnis B',
      initials: 'BS',
      isActive: true,
    ),
    _StudentData(
      name: 'Citra Dewi',
      studentClass: 'Kelas XII — Bisnis A',
      initials: 'CD',
      isActive: false,
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
          _buildStudentList(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Students',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Manajemen data siswa',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Student list
  // ---------------------------------------------------------------------------
  Widget _buildStudentList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(_students.length, (index) {
          final student = _students[index];
          final isLast = index == _students.length - 1;
          return _StudentListItem(student: student, isLast: isLast);
        }),
      ),
    );
  }
}

// =============================================================================
// Private sub-widgets
// =============================================================================

class _StudentListItem extends StatelessWidget {
  const _StudentListItem({
    required this.student,
    required this.isLast,
  });

  final _StudentData student;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingM,
          ),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: _buildInfo()),
              const SizedBox(width: AppDimensions.spacingM),
              _buildStatusBadge(),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider,
            indent: AppDimensions.spacingM,
            endIndent: AppDimensions.spacingM,
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: AppDimensions.avatarM,
      height: AppDimensions.avatarM,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      alignment: Alignment.center,
      child: Text(
        student.initials,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student.name,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          student.studentClass,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final Color bgColor = student.isActive
        ? AppColors.success.withAlpha(26)
        : AppColors.textHint.withAlpha(51);
    final Color textColor =
        student.isActive ? AppColors.success : AppColors.textMuted;
    final String label = student.isActive ? 'Aktif' : 'Tidak Aktif';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// =============================================================================
// Data model (local to this placeholder)
// =============================================================================

class _StudentData {
  const _StudentData({
    required this.name,
    required this.studentClass,
    required this.initials,
    required this.isActive,
  });

  final String name;
  final String studentClass;
  final String initials;
  final bool isActive;
}

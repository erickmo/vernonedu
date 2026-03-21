import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

// ─── DATA ─────────────────────────────────────────────────────────────────────

class _ActiveCourse {
  final String id;
  final String courseName;
  final String batchCode;
  final String field;
  final int completedModules;
  final int totalModules;
  final String startDate;
  final String endDate;
  final Color fieldColor;
  final String facilitator;

  const _ActiveCourse({
    required this.id,
    required this.courseName,
    required this.batchCode,
    required this.field,
    required this.completedModules,
    required this.totalModules,
    required this.startDate,
    required this.endDate,
    required this.fieldColor,
    required this.facilitator,
  });

  double get progress => completedModules / totalModules;
}

class _AvailableCourse {
  final String id;
  final String courseName;
  final String batchCode;
  final String field;
  final Color fieldColor;
  final String startDate;
  final String duration;
  final int quota;
  final int enrolled;
  final String price;

  const _AvailableCourse({
    required this.id,
    required this.courseName,
    required this.batchCode,
    required this.field,
    required this.fieldColor,
    required this.startDate,
    required this.duration,
    required this.quota,
    required this.enrolled,
    required this.price,
  });

  int get remaining => quota - enrolled;
}

const _activeCourses = [
  _ActiveCourse(
    id: '1', courseName: 'Digital Marketing Dasar',
    batchCode: 'DM-2026-05', field: 'Marketing',
    completedModules: 3, totalModules: 10,
    startDate: '1 Mar 2026', endDate: '30 Apr 2026',
    fieldColor: AppColors.accent, facilitator: 'Budi Santoso',
  ),
  _ActiveCourse(
    id: '2', courseName: 'UI/UX Design Fundamentals',
    batchCode: 'UIX-2026-03', field: 'Desain',
    completedModules: 1, totalModules: 8,
    startDate: '10 Mar 2026', endDate: '10 Mei 2026',
    fieldColor: Color(0xFF6A1B9A), facilitator: 'Siti Rahayu',
  ),
];

const _availableCourses = [
  _AvailableCourse(
    id: '1', courseName: 'Barbershop Profesional',
    batchCode: 'BB-2026-04', field: 'Barbershop',
    fieldColor: AppColors.success, startDate: '1 Apr 2026',
    duration: '3 Bulan', quota: 20, enrolled: 14, price: 'Rp 2.500.000',
  ),
  _AvailableCourse(
    id: '2', courseName: 'Tata Boga & Kuliner',
    batchCode: 'TB-2026-06', field: 'Kuliner',
    fieldColor: AppColors.warning, startDate: '15 Apr 2026',
    duration: '4 Bulan', quota: 15, enrolled: 8, price: 'Rp 3.000.000',
  ),
  _AvailableCourse(
    id: '3', courseName: 'Content Creator Pro',
    batchCode: 'CC-2026-02', field: 'Kreator',
    fieldColor: AppColors.primary, startDate: '20 Apr 2026',
    duration: '2 Bulan', quota: 25, enrolled: 19, price: 'Rp 1.800.000',
  ),
  _AvailableCourse(
    id: '4', courseName: 'Coding Web Development',
    batchCode: 'WD-2026-03', field: 'Teknologi',
    fieldColor: AppColors.fieldCoding, startDate: '1 Mei 2026',
    duration: '5 Bulan', quota: 20, enrolled: 12, price: 'Rp 4.500.000',
  ),
];

// ─── PAGE ─────────────────────────────────────────────────────────────────────

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(AppStrings.courseTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: AppStrings.myCourses),
            Tab(text: AppStrings.availableCourses),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyCoursesTab(),
          _AvailableCoursesTab(),
        ],
      ),
    );
  }
}

// ─── TAB: KELAS SAYA ─────────────────────────────────────────────────────────

class _MyCoursesTab extends StatelessWidget {
  const _MyCoursesTab();

  @override
  Widget build(BuildContext context) {
    if (_activeCourses.isEmpty) {
      return const Center(child: Text(AppStrings.noCourse));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      itemCount: _activeCourses.length,
      itemBuilder: (context, i) => _ActiveCourseCard(course: _activeCourses[i]),
    );
  }
}

class _ActiveCourseCard extends StatelessWidget {
  final _ActiveCourse course;
  const _ActiveCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressSection(context),
                const SizedBox(height: AppDimensions.md),
                _buildMetaRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: course.fieldColor.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusLg),
            topRight: Radius.circular(AppDimensions.radiusLg),
          ),
          border: Border(bottom: BorderSide(color: course.fieldColor.withValues(alpha: 0.15))),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: course.fieldColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(Icons.menu_book_rounded, size: 20, color: course.fieldColor),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    course.batchCode,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: course.fieldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              ),
              child: Text(
                course.field,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: course.fieldColor),
              ),
            ),
          ],
        ),
      );

  Widget _buildProgressSection(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(AppStrings.progress, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                '${course.completedModules}/${course.totalModules} modul',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: course.fieldColor),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: course.progress,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(course.fieldColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(course.progress * 100).toInt()}% selesai',
            style: TextStyle(fontSize: 11, color: course.fieldColor, fontWeight: FontWeight.w500),
          ),
        ],
      );

  Widget _buildMetaRow() => Row(
        children: [
          _buildMeta(Icons.person_outline_rounded, course.facilitator),
          const SizedBox(width: AppDimensions.md),
          _buildMeta(Icons.date_range_outlined, '${course.startDate} – ${course.endDate}'),
        ],
      );

  Widget _buildMeta(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}

// ─── TAB: TERSEDIA ────────────────────────────────────────────────────────────

class _AvailableCoursesTab extends StatelessWidget {
  const _AvailableCoursesTab();

  @override
  Widget build(BuildContext context) {
    if (_availableCourses.isEmpty) {
      return const Center(child: Text(AppStrings.noAvailableCourse));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      itemCount: _availableCourses.length,
      itemBuilder: (context, i) => _AvailableCourseCard(course: _availableCourses[i]),
    );
  }
}

class _AvailableCourseCard extends StatelessWidget {
  final _AvailableCourse course;
  const _AvailableCourseCard({required this.course});

  void _showEnrollDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: const Text(AppStrings.enrollConfirmTitle),
        content: Text(
          '${AppStrings.enrollConfirmMessage}\n\n${course.courseName}\n${course.batchCode}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.enrollSuccess),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm)),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimensions.md),
            _buildQuotaBar(),
            const SizedBox(height: AppDimensions.md),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: course.fieldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(Icons.school_rounded, size: 22, color: course.fieldColor),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.courseName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    Text(course.batchCode, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: AppDimensions.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: course.fieldColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                      ),
                      child: Text(course.field, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: course.fieldColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(course.price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Text(course.duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      );

  Widget _buildQuotaBar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kuota: ${course.enrolled}/${course.quota} terdaftar',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('Sisa ${course.remaining}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: course.remaining <= 5 ? AppColors.warning : AppColors.success,
                  )),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: course.enrolled / course.quota,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                course.enrolled / course.quota > 0.8 ? AppColors.warning : course.fieldColor,
              ),
              minHeight: 6,
            ),
          ),
        ],
      );

  Widget _buildFooter(BuildContext context) => Row(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('Mulai ${course.startDate}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _showEnrollDialog(context),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
            child: const Text(AppStrings.enrollNow, style: TextStyle(fontSize: 13)),
          ),
        ],
      );
}

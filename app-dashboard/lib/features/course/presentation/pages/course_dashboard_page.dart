import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/course_entity.dart';

// ── Internal Models ───────────────────────────────────────────────────────────

class _MasterCourseDetail {
  final String id;
  final String courseCode;
  final String courseName;
  final String field;
  final String description;
  final List<String> coreCompetencies;
  final String status;

  bool get isActive => status == 'active';

  _MasterCourseDetail({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.field,
    required this.description,
    required this.coreCompetencies,
    required this.status,
  });

  factory _MasterCourseDetail.fromJson(Map<String, dynamic> json) =>
      _MasterCourseDetail(
        id: json['id'] as String? ?? '',
        courseCode: json['course_code'] as String? ?? '',
        courseName: json['course_name'] as String? ?? '',
        field: json['field'] as String? ?? '',
        description: json['description'] as String? ?? '',
        coreCompetencies: (json['core_competencies'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        status: json['status'] as String? ?? 'active',
      );
}

class _CourseTypeData {
  final String id;
  final String typeName;
  final bool isActive;
  final double? minPrice;
  final double? maxPrice;

  _CourseTypeData({
    required this.id,
    required this.typeName,
    required this.isActive,
    this.minPrice,
    this.maxPrice,
  });

  factory _CourseTypeData.fromJson(Map<String, dynamic> json) =>
      _CourseTypeData(
        id: json['id'] as String? ?? '',
        typeName: json['type_name'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        minPrice: (json['price_min'] as num?)?.toDouble(),
        maxPrice: (json['price_max'] as num?)?.toDouble(),
      );
}

class _BatchData {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String status;
  final int maxParticipants;
  final int sessionCount;
  final String location;
  final int enrollmentCount;

  _BatchData({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.maxParticipants,
    required this.sessionCount,
    required this.location,
    required this.enrollmentCount,
  });

  factory _BatchData.fromJson(Map<String, dynamic> json) => _BatchData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String? ?? '',
        status: json['status'] as String? ?? 'upcoming',
        maxParticipants: json['max_participants'] as int? ?? 0,
        sessionCount: json['session_count'] as int? ?? 0,
        location: json['location'] as String? ?? '',
        enrollmentCount: json['enrollment_count'] as int? ?? 0,
      );
}

class _StudentData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String batchName;
  final String enrollStatus;
  final String paymentStatus;
  final String enrolledAt;

  _StudentData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.batchName,
    required this.enrollStatus,
    required this.paymentStatus,
    required this.enrolledAt,
  });

  factory _StudentData.fromJson(Map<String, dynamic> json) => _StudentData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        batchName: json['batch_name'] as String? ?? '',
        enrollStatus: json['enroll_status'] as String? ?? '',
        paymentStatus: json['payment_status'] as String? ?? '',
        enrolledAt: json['enrolled_at'] as String? ?? '',
      );
}

class _CourseVersionData {
  final String id;
  final String versionNumber;
  final String status;
  final String changeType;

  _CourseVersionData({
    required this.id,
    required this.versionNumber,
    required this.status,
    required this.changeType,
  });

  factory _CourseVersionData.fromJson(Map<String, dynamic> json) =>
      _CourseVersionData(
        id: json['id'] as String? ?? '',
        versionNumber: json['version_number'] as String? ?? '',
        status: json['status'] as String? ?? '',
        changeType: json['change_type'] as String? ?? '',
      );
}

class _CourseModuleData {
  final String id;
  final String title;
  final int sequence;
  final int durationHours;
  final String description;
  final int sessionCount;
  final List<String> fileLinks;

  _CourseModuleData({
    required this.id,
    required this.title,
    required this.sequence,
    required this.durationHours,
    required this.description,
    required this.sessionCount,
    required this.fileLinks,
  });

  factory _CourseModuleData.fromJson(Map<String, dynamic> json) =>
      _CourseModuleData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        sequence: json['sequence'] as int? ?? 0,
        durationHours: json['duration_hours'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        sessionCount: json['session_count'] as int? ?? 0,
        fileLinks: (json['file_links'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

class _MentorData {
  final String id;
  final String name;
  final String role; // 'course_owner' | 'mentor' | 'facilitator'
  final String email;
  final String phone;
  final String? specialization;
  final String? photoUrl;

  _MentorData({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.specialization,
    this.photoUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory _MentorData.fromJson(Map<String, dynamic> json) => _MentorData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'mentor',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        specialization: json['specialization'] as String?,
        photoUrl: json['photo_url'] as String?,
      );
}

class _TalentMember {
  final String id;
  final String participantName;
  final String participantEmail;
  final String status;
  final DateTime joinedAt;
  final double? testScore;

  _TalentMember({
    required this.id,
    required this.participantName,
    required this.participantEmail,
    required this.status,
    required this.joinedAt,
    this.testScore,
  });

  bool get isActive => status == 'active';
  bool get isPlaced => status == 'placed';

  String get initials {
    final parts = participantName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return participantName.isNotEmpty ? participantName[0].toUpperCase() : '?';
  }

  String get statusLabel => switch (status) {
        'active' => 'Aktif',
        'placed' => 'Ditempatkan',
        'inactive' => 'Nonaktif',
        _ => status,
      };

  Color get statusColor => switch (status) {
        'active' => AppColors.success,
        'placed' => AppColors.primary,
        'inactive' => AppColors.textSecondary,
        _ => AppColors.textSecondary,
      };

  factory _TalentMember.fromJson(Map<String, dynamic> json) => _TalentMember(
        id: json['id'] as String? ?? '',
        participantName: json['participant_name'] as String? ?? '',
        participantEmail: json['participant_email'] as String? ?? '',
        status: json['talentpool_status'] as String? ?? 'active',
        joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ??
            DateTime.now(),
        testScore: (json['test_score'] as num?)?.toDouble(),
      );
}

class _PageData {
  final _MasterCourseDetail course;
  final List<_CourseTypeData> types;
  final List<_BatchData> batches;
  final List<_StudentData> students;
  final List<_MentorData> mentors;
  final List<_TalentMember> talentMembers;

  _PageData({
    required this.course,
    required this.types,
    required this.batches,
    required this.students,
    required this.mentors,
    required this.talentMembers,
  });
}

// ── Page Root ─────────────────────────────────────────────────────────────────

class CourseDashboardPage extends StatefulWidget {
  final String courseId;

  const CourseDashboardPage({super.key, required this.courseId});

  @override
  State<CourseDashboardPage> createState() => _CourseDashboardPageState();
}

class _CourseDashboardPageState extends State<CourseDashboardPage>
    with SingleTickerProviderStateMixin {
  late Future<_PageData> _dataFuture;
  late TabController _tabController;

  static const _tabCount = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_PageData> _loadData() async {
    final api = getIt<ApiClient>().dio;
    final cid = widget.courseId;

    // Required calls
    final results = await Future.wait([
      api.get('/curriculum/courses/$cid'),
      api.get('/curriculum/courses/$cid/types'),
      api.get('/curriculum/courses/$cid/batches'),
      api.get('/curriculum/courses/$cid/students'),
    ]);

    // Optional calls — swallow errors gracefully
    dynamic rawMentors;
    dynamic rawTalent;
    try {
      final r = await api.get('/curriculum/courses/$cid/mentors');
      rawMentors = r.data;
    } catch (_) {}
    try {
      final r = await api.get('/talentpool?master_course_id=$cid&limit=100');
      rawTalent = r.data;
    } catch (_) {}

    // course
    final rawCourse = results[0].data;
    final courseJson = (rawCourse is Map && rawCourse['data'] != null)
        ? rawCourse['data'] as Map<String, dynamic>
        : rawCourse as Map<String, dynamic>;

    // types
    final rawTypes = results[1].data;
    final typesList = (rawTypes is Map && rawTypes['data'] != null)
        ? (rawTypes['data'] as List).cast<Map<String, dynamic>>()
        : (rawTypes is List ? rawTypes : <dynamic>[]).cast<Map<String, dynamic>>();

    // batches
    final rawBatches = results[2].data;
    final batchList = (rawBatches is Map && rawBatches['data'] != null)
        ? (rawBatches['data'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    // students
    final rawStudents = results[3].data;
    final studentList = (rawStudents is Map && rawStudents['data'] != null)
        ? (rawStudents['data'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    // mentors (optional)
    final mentorList = rawMentors != null &&
            rawMentors is Map &&
            rawMentors['data'] != null
        ? (rawMentors['data'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    // talent pool (optional)
    final talentList = rawTalent != null &&
            rawTalent is Map &&
            rawTalent['data'] != null
        ? (rawTalent['data'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return _PageData(
      course: _MasterCourseDetail.fromJson(courseJson),
      types: typesList.map((e) => _CourseTypeData.fromJson(e)).toList(),
      batches: batchList.map((e) => _BatchData.fromJson(e)).toList(),
      students: studentList.map((e) => _StudentData.fromJson(e)).toList(),
      mentors: mentorList.map((e) => _MentorData.fromJson(e)).toList(),
      talentMembers: talentList.map((e) => _TalentMember.fromJson(e)).toList(),
    );
  }

  void _refresh() => setState(() {
        _dataFuture = _loadData();
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PageData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ErrorView(
            message: snapshot.error?.toString() ?? 'Gagal memuat data course',
            onRetry: _refresh,
          );
        }
        return _DashboardBody(
          courseId: widget.courseId,
          data: snapshot.data!,
          onRefresh: _refresh,
          tabController: _tabController,
        );
      },
    );
  }
}

// ── Dashboard Body ────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final String courseId;
  final _PageData data;
  final VoidCallback onRefresh;
  final TabController tabController;

  const _DashboardBody({
    required this.courseId,
    required this.data,
    required this.onRefresh,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final course = data.course;
    final batches = data.batches;
    final students = data.students;

    final berjalan = batches.where((b) => b.status == 'ongoing').length;
    final selesai = batches.where((b) => b.status == 'completed').length;
    final upcoming = batches.where((b) => b.status == 'upcoming').length;
    final totalSiswa = students.length;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _Breadcrumb(courseName: course.courseName),
          const SizedBox(height: AppDimensions.sm),

          // Title Row
          _TitleRow(course: course, courseId: courseId, onRefresh: onRefresh),
          const SizedBox(height: AppDimensions.md - 4),

          // Stats Row
          _StatsRow(
            berjalan: berjalan,
            selesai: selesai,
            upcoming: upcoming,
            totalSiswa: totalSiswa,
          ),
          const SizedBox(height: AppDimensions.md - 4),

          // TabBar + TabBarView wrapped in card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // TabBar
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: TabBar(
                      controller: tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontSize: 13),
                      tabs: const [
                        Tab(text: 'Informasi'),
                        Tab(text: 'Tipe Pembelajaran'),
                        Tab(text: 'Kalender'),
                        Tab(text: 'Mentor & Fasilitator'),
                        Tab(text: 'Siswa'),
                        Tab(text: 'Karir & TalentPool'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: [
                        _TabInformasi(
                          course: course,
                          batches: batches,
                          students: students,
                        ),
                        _TabTipePembelajaran(
                          courseId: courseId,
                          types: data.types,
                          onRefresh: onRefresh,
                        ),
                        _TabKalender(batches: batches),
                        _TabMentor(mentors: data.mentors),
                        _TabSiswa(students: students),
                        _TabKarir(
                          courseId: courseId,
                          courseName: data.course.courseName,
                          talentMembers: data.talentMembers,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breadcrumb ────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  final String courseName;

  const _Breadcrumb({required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/curriculum'),
          child: Text(
            'Course',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 14, color: AppColors.textHint),
        ),
        Text(
          courseName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ── Title Row ─────────────────────────────────────────────────────────────────

class _TitleRow extends StatelessWidget {
  final _MasterCourseDetail course;
  final String courseId;
  final VoidCallback onRefresh;

  const _TitleRow({
    required this.course,
    required this.courseId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  course.courseName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              if (course.courseCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    course.courseCode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: AppDimensions.sm),
              _StatusBadge(isActive: course.isActive),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Buat Batch'),
        ),
        const SizedBox(width: AppDimensions.sm),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit Course'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Arsip',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int berjalan;
  final int selesai;
  final int upcoming;
  final int totalSiswa;

  const _StatsRow({
    required this.berjalan,
    required this.selesai,
    required this.upcoming,
    required this.totalSiswa,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Batch Berjalan',
            value: '$berjalan',
            color: AppColors.success,
            icon: Icons.play_circle_outline,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'Batch Selesai',
            value: '$selesai',
            color: AppColors.textSecondary,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'Akan Datang',
            value: '$upcoming',
            color: AppColors.info,
            icon: Icons.schedule_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'Total Siswa',
            value: '$totalSiswa',
            color: AppColors.primary,
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        const Expanded(
          child: _StatCard(
            label: 'Total Pendapatan',
            value: 'Rp 0',
            color: AppColors.secondary,
            icon: Icons.payments_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Informasi ──────────────────────────────────────────────────────────

class _TabInformasi extends StatelessWidget {
  final _MasterCourseDetail course;
  final List<_BatchData> batches;
  final List<_StudentData> students;

  const _TabInformasi({
    required this.course,
    required this.batches,
    required this.students,
  });

  Color _fieldColor(String field) => switch (field) {
        'coding' => AppColors.primary,
        'culinary' => AppColors.warning,
        'barber' => AppColors.roleDeptLeader,
        'public_speaking' => AppColors.info,
        'entrepreneurship' => AppColors.roleCourseOwner,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final fieldColor = _fieldColor(course.field);
    final fieldLabel = CourseField.fromString(course.field).label;
    final alumni = students.where((s) => s.enrollStatus == 'completed').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          _SectionCard(
            title: 'Informasi Course',
            icon: Icons.info_outline,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabelValue(
                        label: 'Bidang',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: fieldColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            fieldLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: fieldColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      _LabelValue(
                        label: 'Deskripsi',
                        child: Text(
                          course.description.isNotEmpty
                              ? course.description
                              : 'Belum ada deskripsi',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      if (course.coreCompetencies.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.sm),
                        _LabelValue(
                          label: 'Kompetensi Inti',
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: course.coreCompetencies
                                .map((c) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusSm),
                                      ),
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.lg),
                // Right
                const Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _MetaItem(
                          icon: Icons.person_outline,
                          label: 'Course Owner',
                          value: '—'),
                      _MetaItem(
                          icon: Icons.lock_outline,
                          label: 'Prerequisite',
                          value: '—'),
                      _MetaItem(
                          icon: Icons.arrow_forward_outlined,
                          label: 'Rekomendasi Lanjutan',
                          value: '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Batch Section
          _SectionCard(
            title: 'Batch',
            icon: Icons.view_list_outlined,
            child: batches.isEmpty
                ? const _EmptyState(
                    icon: Icons.event_available_outlined,
                    message: 'Belum ada batch')
                : Column(
                    children: batches
                        .map((b) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppDimensions.sm),
                              child: _BatchCard(batch: b),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Alumni Section
          _SectionCard(
            title: 'Alumni',
            icon: Icons.school_outlined,
            child: alumni.isEmpty
                ? const _EmptyState(
                    icon: Icons.people_outline, message: 'Belum ada alumni')
                : Column(
                    children: alumni
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppDimensions.xs),
                              child: _AlumniRow(student: s),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabelValue({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final _BatchData batch;

  const _BatchCard({required this.batch});

  Color _statusColor(String status) => switch (status) {
        'ongoing' => AppColors.success,
        'upcoming' => AppColors.info,
        'completed' => AppColors.textSecondary,
        'cancelled' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  String _statusLabel(String status) => switch (status) {
        'ongoing' => 'Berjalan',
        'upcoming' => 'Akan Datang',
        'completed' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(batch.status);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                Text(
                  '${batch.startDate} — ${batch.endDate}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Text(
              _statusLabel(batch.status),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Text(
            '${batch.enrollmentCount}/${batch.maxParticipants} siswa',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AlumniRow extends StatelessWidget {
  final _StudentData student;

  const _AlumniRow({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.xs, horizontal: AppDimensions.sm),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          Text(
            student.batchName,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.sm),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2: Tipe Pembelajaran ──────────────────────────────────────────────────

class _TabTipePembelajaran extends StatefulWidget {
  final String courseId;
  final List<_CourseTypeData> types;
  final VoidCallback onRefresh;

  const _TabTipePembelajaran({
    required this.courseId,
    required this.types,
    required this.onRefresh,
  });

  @override
  State<_TabTipePembelajaran> createState() => _TabTipePembelajaranState();
}

class _TabTipePembelajaranState extends State<_TabTipePembelajaran>
    with TickerProviderStateMixin {
  TabController? _typeTabController;
  bool _provisioning = false;

  static const _allTypeNames = [
    'regular',
    'private',
    'company_training',
    'collab_university',
    'collab_school',
    'program_karir',
  ];

  static Color _typeColor(String typeName) => switch (typeName) {
        'regular' => AppColors.primary,
        'private' => AppColors.secondary,
        'company_training' => AppColors.warning,
        'collab_university' => AppColors.info,
        'collab_school' => AppColors.roleDeptLeader,
        'program_karir' => AppColors.roleFacilitator,
        _ => AppColors.textSecondary,
      };

  static String _typeLabel(String typeName) => switch (typeName) {
        'regular' => 'Regular',
        'private' => 'Private',
        'company_training' => 'Company Training',
        'collab_university' => 'Kolaborasi Universitas',
        'collab_school' => 'Kolaborasi Sekolah',
        'program_karir' => 'Program Karir',
        _ => typeName,
      };

  @override
  void initState() {
    super.initState();
    _initTabController();
    if (widget.types.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _provisionAllTypes());
    }
  }

  @override
  void didUpdateWidget(_TabTipePembelajaran oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.types.length != widget.types.length) {
      _typeTabController?.dispose();
      _initTabController();
    }
  }

  void _initTabController() {
    if (widget.types.isNotEmpty) {
      _typeTabController = TabController(
        length: widget.types.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _typeTabController?.dispose();
    super.dispose();
  }

  Future<void> _provisionAllTypes() async {
    if (!mounted) return;
    setState(() => _provisioning = true);
    final api = getIt<ApiClient>().dio;
    for (final typeName in _allTypeNames) {
      try {
        await api.post(
          '/curriculum/courses/${widget.courseId}/types',
          data: {'type_name': typeName, 'is_active': true},
        );
      } catch (_) {
        // ignore individual failures — type may already exist
      }
    }
    if (mounted) {
      setState(() => _provisioning = false);
      widget.onRefresh();
    }
  }

  Future<void> _toggleTypeActive(
      BuildContext context, _CourseTypeData type) async {
    try {
      await getIt<ApiClient>().dio.put(
        '/curriculum/types/${type.id}',
        data: {'is_active': !type.isActive},
      );
      widget.onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_provisioning || widget.types.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppDimensions.sm),
            Text(
              'Menyiapkan tipe pembelajaran...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _typeTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicator: const BoxDecoration(),
          labelPadding: const EdgeInsets.only(right: 8),
          tabs: widget.types.map((t) {
            final color = _typeColor(t.typeName);
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: t.isActive ? color : AppColors.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCircle),
                  border: Border.all(
                    color: t.isActive ? color : AppColors.border,
                  ),
                ),
                child: Text(
                  _typeLabel(t.typeName),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        t.isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.sm),
        Expanded(
          child: TabBarView(
            controller: _typeTabController,
            children: widget.types
                .map((t) => _TypeDetailView(
                      type: t,
                      onToggleActive: () => _toggleTypeActive(context, t),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TypeDetailView extends StatefulWidget {
  final _CourseTypeData type;
  final VoidCallback onToggleActive;

  const _TypeDetailView({required this.type, required this.onToggleActive});

  @override
  State<_TypeDetailView> createState() => _TypeDetailViewState();
}

class _TypeDetailViewState extends State<_TypeDetailView> {
  late Future<_TypeDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TypeDetail> _load() async {
    final api = getIt<ApiClient>().dio;
    final vRes =
        await api.get('/curriculum/types/${widget.type.id}/versions');
    final rawV = vRes.data;
    final vList = (rawV is Map && rawV['data'] != null)
        ? (rawV['data'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final versions =
        vList.map((e) => _CourseVersionData.fromJson(e)).toList();

    // Find approved version
    final approved = versions.where((v) => v.status == 'approved').toList();
    List<_CourseModuleData> modules = [];
    _CourseVersionData? activeVersion;
    if (approved.isNotEmpty) {
      activeVersion = approved.first;
      final mRes = await api
          .get('/curriculum/versions/${activeVersion.id}/modules');
      final rawM = mRes.data;
      final mList = (rawM is Map && rawM['data'] != null)
          ? (rawM['data'] as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      modules = mList.map((e) => _CourseModuleData.fromJson(e)).toList();
    }
    return _TypeDetail(
        versions: versions, activeVersion: activeVersion, modules: modules);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TypeDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style:
                    const TextStyle(color: AppColors.error, fontSize: 13)),
          );
        }
        final detail = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(
              top: AppDimensions.sm,
              left: AppDimensions.md,
              right: AppDimensions.md,
              bottom: AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + action row
              Row(
                children: [
                  if (detail.activeVersion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Text(
                        'Versi Aktif: v${detail.activeVersion!.versionNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Belum ada versi aktif',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        context.go('/curriculum/types/${widget.type.id}'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                    child: const Text('Lihat Semua Versi →'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              // Action buttons
              Wrap(
                spacing: AppDimensions.sm,
                runSpacing: AppDimensions.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_outlined, size: 14),
                    label: const Text('Usulkan Versi Baru'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_box_outlined, size: 14),
                    label: const Text('Tambah Modul'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit Tipe'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              if (detail.modules.isEmpty)
                const _EmptyState(
                    icon: Icons.layers_outlined,
                    message: 'Belum ada modul untuk versi ini')
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Table(
                      columnWidths: const {
                        0: FixedColumnWidth(48),
                        1: FlexColumnWidth(3),
                        2: FixedColumnWidth(100),
                        3: FlexColumnWidth(2),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.5)),
                        bottom: const BorderSide(color: AppColors.border),
                      ),
                      children: [
                        // Header
                        const TableRow(
                          decoration: BoxDecoration(
                              color: AppColors.surfaceVariant),
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Text('No',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Text('Judul',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Text('Jumlah Sesi',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Text('Files',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        // Rows
                        ...detail.modules.map((m) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: Text('${m.sequence}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: Text(m.title,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: Text('${m.sessionCount}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: m.fileLinks.isEmpty
                                      ? const Text('—',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  AppColors.textSecondary))
                                      : Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: m.fileLinks
                                              .map((f) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .primarySurface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppDimensions
                                                                  .radiusSm),
                                                    ),
                                                    child: Text(
                                                      f,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                ),
                              ],
                            )),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeDetail {
  final List<_CourseVersionData> versions;
  final _CourseVersionData? activeVersion;
  final List<_CourseModuleData> modules;

  _TypeDetail({
    required this.versions,
    required this.activeVersion,
    required this.modules,
  });
}

// ── Tab 3: Kalender ───────────────────────────────────────────────────────────

class _TabKalender extends StatefulWidget {
  final List<_BatchData> batches;

  const _TabKalender({required this.batches});

  @override
  State<_TabKalender> createState() => _TabKalenderState();
}

class _TabKalenderState extends State<_TabKalender> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() => setState(() {
        _displayMonth =
            DateTime(_displayMonth.year, _displayMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _displayMonth =
            DateTime(_displayMonth.year, _displayMonth.month + 1);
      });

  // Returns batch events for a given date
  List<_BatchData> _eventsOn(DateTime day) {
    return widget.batches.where((b) {
      final start = DateTime.tryParse(b.startDate);
      final end = DateTime.tryParse(b.endDate);
      if (start == null || end == null) return false;
      final d = DateTime(day.year, day.month, day.day);
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      return !d.isBefore(s) && !d.isAfter(e);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _monthName(_displayMonth.month);
    final year = _displayMonth.year;
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    // Monday=0 offset
    final startOffset = (firstDay.weekday - 1) % 7;

    final batchColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
      AppColors.info,
      AppColors.roleDeptLeader,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: nav arrows + month title
                Row(
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left, size: 20),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(
                        '$monthLabel $year',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right, size: 20),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                // Day headers
                Row(
                  children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                      .map((d) => Expanded(
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppDimensions.xs),
                // Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: startOffset + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < startOffset) return const SizedBox();
                    final day = index - startOffset + 1;
                    final date = DateTime(
                        _displayMonth.year, _displayMonth.month, day);
                    final events = _eventsOn(date);
                    final isToday = date.year == DateTime.now().year &&
                        date.month == DateTime.now().month &&
                        date.day == DateTime.now().day;
                    return SizedBox(
                      width: 32,
                      height: 32,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.primary : null,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isToday
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          if (events.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: events
                                  .take(3)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((e) => Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.only(
                                            top: 1, right: 1),
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? Colors.white70
                                              : batchColors[e.key %
                                                  batchColors.length],
                                          shape: BoxShape.circle,
                                        ),
                                      ))
                                  .toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          // Legend: Batch list
          if (widget.batches.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Jadwal Batch',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  ...widget.batches.asMap().entries.map((entry) {
                    final b = entry.value;
                    final color =
                        batchColors[entry.key % batchColors.length];
                    final statusColor = switch (b.status) {
                      'ongoing' => AppColors.success,
                      'upcoming' => AppColors.info,
                      'completed' => AppColors.textSecondary,
                      _ => AppColors.textSecondary,
                    };
                    final statusLabel = switch (b.status) {
                      'ongoing' => 'Berjalan',
                      'upcoming' => 'Akan Datang',
                      'completed' => 'Selesai',
                      _ => b.status,
                    };
                    return Container(
                      margin: const EdgeInsets.only(
                          bottom: AppDimensions.xs),
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${b.startDate} — ${b.endDate}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusCircle),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthName(int month) => [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ][month];
}

// ── Tab 4: Mentor & Fasilitator ───────────────────────────────────────────────

class _TabMentor extends StatelessWidget {
  final List<_MentorData> mentors;

  const _TabMentor({required this.mentors});

  void _showAddPersonDialog(BuildContext context, String role) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleLabel = role == 'course_owner' ? 'Course Owner' : 'Fasilitator';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah $roleLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = mentors.where((m) => m.role == 'course_owner').toList();
    final facilitatorList =
        mentors.where((m) => m.role == 'facilitator').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Owner Section
          _SectionCardWithAction(
            title: 'Course Owner',
            icon: Icons.manage_accounts_outlined,
            actionLabel: 'Tambah Course Owner',
            onAction: () => _showAddPersonDialog(context, 'course_owner'),
            child: owner.isEmpty
                ? const _EmptyState(
                    icon: Icons.person_outline,
                    message: 'Belum ada course owner')
                : Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.sm,
                    children: owner
                        .map((m) => _PersonCard(person: m, showDelete: false))
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Fasilitator Section
          _SectionCardWithAction(
            title: 'Daftar Fasilitator',
            icon: Icons.support_agent_outlined,
            actionLabel: 'Tambah Fasilitator',
            onAction: () => _showAddPersonDialog(context, 'facilitator'),
            child: facilitatorList.isEmpty
                ? const _EmptyState(
                    icon: Icons.person_outline,
                    message: 'Belum ada fasilitator')
                : Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.sm,
                    children: facilitatorList
                        .map((m) => _PersonCard(person: m, showDelete: true))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionCardWithAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionCardWithAction({
    required this.title,
    required this.icon,
    required this.child,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 14),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final _MentorData person;
  final bool showDelete;

  const _PersonCard({required this.person, required this.showDelete});

  Color get _roleColor => switch (person.role) {
        'course_owner' => AppColors.roleCourseOwner,
        'facilitator' => AppColors.roleFacilitator,
        _ => AppColors.textSecondary,
      };

  String get _roleLabel => switch (person.role) {
        'course_owner' => 'Course Owner',
        'facilitator' => 'Fasilitator',
        _ => person.role,
      };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: AppDimensions.avatarLg,
                height: AppDimensions.avatarLg,
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    person.initials,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2, bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Text(
                        _roleLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _roleColor,
                        ),
                      ),
                    ),
                    if (person.email.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              person.email,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (person.phone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            person.phone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    if (person.specialization != null &&
                        person.specialization!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          person.specialization!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDelete)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dihapus')),
                );
              },
              child: const Icon(Icons.close,
                  size: 16, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

// ── Tab 5: Siswa ──────────────────────────────────────────────────────────────

class _TabSiswa extends StatefulWidget {
  final List<_StudentData> students;

  const _TabSiswa({required this.students});

  @override
  State<_TabSiswa> createState() => _TabSiswaState();
}

class _TabSiswaState extends State<_TabSiswa> {
  static const _pageSize = 10;
  int _currentPage = 0;
  String _filterName = '';
  String _filterPhone = '';
  String _statusFilter = 'all';

  List<_StudentData> get _filtered => widget.students.where((s) {
        final nameOk = _filterName.isEmpty ||
            s.name.toLowerCase().contains(_filterName.toLowerCase());
        final phoneOk = _filterPhone.isEmpty ||
            s.phone.contains(_filterPhone);
        final statusOk = _statusFilter == 'all' ||
            (_statusFilter == 'active' && s.enrollStatus == 'active') ||
            (_statusFilter == 'alumni' && s.enrollStatus == 'completed');
        return nameOk && phoneOk && statusOk;
      }).toList();

  List<_StudentData> get _paginated {
    final all = _filtered;
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final paginated = _paginated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filter chips
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: Wrap(
            spacing: AppDimensions.xs,
            children: [
              ('all', 'Semua'),
              ('active', 'Aktif'),
              ('alumni', 'Alumni'),
            ].map((opt) {
              final selected = _statusFilter == opt.$1;
              return FilterChip(
                label: Text(opt.$2),
                selected: selected,
                onSelected: (_) => setState(() {
                  _statusFilter = opt.$1;
                  _currentPage = 0;
                }),
                selectedColor: AppColors.primarySurface,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ),
        // Filter Row
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filter nama...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    prefixIcon: const Icon(Icons.person_search_outlined,
                        size: 16),
                  ),
                  onChanged: (v) => setState(() {
                    _filterName = v;
                    _currentPage = 0;
                  }),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filter no. telp...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 16),
                  ),
                  onChanged: (v) => setState(() {
                    _filterPhone = v;
                    _currentPage = 0;
                  }),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Text(
                '${filtered.length} siswa',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        // Student Cards
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(
                  icon: Icons.school_outlined,
                  message: 'Belum ada siswa terdaftar')
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 340,
                          childAspectRatio: 2.6,
                          mainAxisSpacing: AppDimensions.sm,
                          crossAxisSpacing: AppDimensions.sm,
                        ),
                        itemCount: paginated.length,
                        itemBuilder: (ctx, i) =>
                            _StudentCard(student: paginated[i]),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    // Pagination
                    _Pagination(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      onPrev: _currentPage > 0
                          ? () =>
                              setState(() => _currentPage--)
                          : null,
                      onNext: _currentPage < _totalPages - 1
                          ? () =>
                              setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final _StudentData student;

  const _StudentCard({required this.student});

  String get _initials {
    final parts = student.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return student.name.isNotEmpty ? student.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarMd,
            height: AppDimensions.avatarMd,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.phone.isNotEmpty ? student.phone : student.email,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.batchName,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _EnrollStatusChip(status: student.enrollStatus),
              const SizedBox(height: 3),
              _PaymentChip(status: student.paymentStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            foregroundColor:
                onPrev != null ? AppColors.primary : AppColors.textHint,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Text(
            'Halaman ${currentPage + 1} / $totalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            foregroundColor:
                onNext != null ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _EnrollStatusChip extends StatelessWidget {
  final String status;

  const _EnrollStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => AppColors.success,
      'completed' => AppColors.primary,
      'dropped' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final label = switch (status) {
      'active' => 'Aktif',
      'completed' => 'Selesai',
      'dropped' => 'Drop',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String status;

  const _PaymentChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => AppColors.success,
      'pending' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final label = switch (status) {
      'paid' => 'Lunas',
      'pending' => 'Pending',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Tab 6: Karir & TalentPool ─────────────────────────────────────────────────

class _TabKarir extends StatefulWidget {
  final String courseId;
  final String courseName;
  final List<_TalentMember> talentMembers;

  const _TabKarir({
    required this.courseId,
    required this.courseName,
    required this.talentMembers,
  });

  @override
  State<_TabKarir> createState() => _TabKarirState();
}

class _TabKarirState extends State<_TabKarir> {
  final List<Map<String, dynamic>> _careers = [
    {
      'title': 'Junior Developer',
      'level': 'Entry Level',
      'color': AppColors.primary,
      'icon': Icons.code_outlined,
      'skills': ['HTML/CSS', 'JavaScript', 'Git'],
      'salary': 'Rp 4–7 jt',
    },
    {
      'title': 'Software Engineer',
      'level': 'Mid Level',
      'color': AppColors.secondary,
      'icon': Icons.developer_mode_outlined,
      'skills': ['Backend', 'Database', 'API Design'],
      'salary': 'Rp 8–15 jt',
    },
    {
      'title': 'Tech Lead',
      'level': 'Senior Level',
      'color': AppColors.warning,
      'icon': Icons.architecture_outlined,
      'skills': ['System Design', 'Team Lead', 'DevOps'],
      'salary': 'Rp 15–30 jt',
    },
  ];

  String _talentSearch = '';
  String _talentStatusFilter = 'all';

  List<_TalentMember> get _filteredTalent =>
      widget.talentMembers.where((t) {
        final nameOk = _talentSearch.isEmpty ||
            t.participantName
                .toLowerCase()
                .contains(_talentSearch.toLowerCase());
        final statusOk = _talentStatusFilter == 'all' ||
            (_talentStatusFilter == 'active' && t.isActive) ||
            (_talentStatusFilter == 'placed' && t.isPlaced);
        return nameOk && statusOk;
      }).toList();

  void _showAddCareerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Jalur Karir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Karir')),
            const SizedBox(height: AppDimensions.sm),
            TextField(
                controller: levelCtrl,
                decoration: const InputDecoration(labelText: 'Level')),
            const SizedBox(height: AppDimensions.sm),
            TextField(
                controller: salaryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Kisaran Gaji')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _careers.add({
                    'title': nameCtrl.text,
                    'level': levelCtrl.text,
                    'color': AppColors.info,
                    'icon': Icons.work_outline,
                    'skills': <String>[],
                    'salary': salaryCtrl.text,
                  });
                });
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTalent = widget.talentMembers.where((t) => t.isActive).toList();
    final placedTalent = widget.talentMembers.where((t) => t.isPlaced).toList();
    final filtered = _filteredTalent;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Talent Pool',
                  value: '${widget.talentMembers.length}',
                  color: AppColors.primary,
                  icon: Icons.group_outlined,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _StatCard(
                  label: 'Aktif di Pool',
                  value: '${activeTalent.length}',
                  color: AppColors.success,
                  icon: Icons.person_search_outlined,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _StatCard(
                  label: 'Sudah Ditempatkan',
                  value: '${placedTalent.length}',
                  color: AppColors.secondary,
                  icon: Icons.work_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Career Paths Card
          _SectionCardWithAction(
            title: 'Jalur Karir Terkait',
            icon: Icons.trending_up_outlined,
            actionLabel: 'Tambah Karir',
            onAction: () => _showAddCareerDialog(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Karir yang dapat dicapai lulusan dari course ${widget.courseName}:',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.sm),
                Wrap(
                  spacing: AppDimensions.sm,
                  runSpacing: AppDimensions.sm,
                  children: _careers
                      .asMap()
                      .entries
                      .map((entry) => _CareerCard(
                            career: entry.value,
                            onDelete: () => setState(
                                () => _careers.removeAt(entry.key)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Talent Pool Members
          _SectionCard(
            title: 'Siswa di Talent Pool',
            icon: Icons.people_alt_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search + filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari nama...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          prefixIcon: const Icon(
                              Icons.person_search_outlined,
                              size: 16),
                        ),
                        onChanged: (v) =>
                            setState(() => _talentSearch = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                Wrap(
                  spacing: AppDimensions.xs,
                  children: [
                    ('all', 'Semua'),
                    ('active', 'Tersedia'),
                    ('placed', 'Ditempatkan'),
                  ].map((opt) {
                    final selected = _talentStatusFilter == opt.$1;
                    return FilterChip(
                      label: Text(opt.$2),
                      selected: selected,
                      onSelected: (_) => setState(
                          () => _talentStatusFilter = opt.$1),
                      selectedColor: AppColors.primarySurface,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimensions.sm),
                if (filtered.isEmpty)
                  const _EmptyState(
                    icon: Icons.person_search_outlined,
                    message: 'Belum ada siswa di talent pool',
                  )
                else
                  ...filtered.map((t) => _TalentMemberRow(member: t)),
                const SizedBox(height: AppDimensions.sm),
                OutlinedButton.icon(
                  onPressed: () => context.go('/talentpool'),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Kelola Talent Pool'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerCard extends StatelessWidget {
  final Map<String, dynamic> career;
  final VoidCallback onDelete;

  const _CareerCard({required this.career, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = career['color'] as Color;
    final skills = career['skills'] as List<String>;

    return Stack(
      children: [
        Container(
      width: 220,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(career['icon'] as IconData,
                    size: 16, color: color),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      career['title'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      career['level'] as String,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppDimensions.xs),
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 11, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(
                career['salary'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onDelete,
            child: const Icon(Icons.close,
                size: 14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _TalentMemberRow extends StatelessWidget {
  final _TalentMember member;

  const _TalentMemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.sm, horizontal: AppDimensions.xs),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarSm,
            height: AppDimensions.avatarSm,
            decoration: BoxDecoration(
              color: member.statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: member.statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.participantName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  member.participantEmail,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (member.testScore != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    member.testScore!.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'skor',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: member.statusColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Text(
              member.statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: member.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.md),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}


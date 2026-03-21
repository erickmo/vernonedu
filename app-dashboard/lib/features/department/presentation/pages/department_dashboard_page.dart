import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/department_batch_entity.dart';
import '../../domain/entities/department_course_entity.dart';
import '../../domain/entities/department_student_entity.dart';
import '../../domain/entities/department_talentpool_entity.dart';
import '../cubit/department_dashboard_cubit.dart';
import '../cubit/department_dashboard_state.dart';

class DepartmentDashboardPage extends StatelessWidget {
  final String departmentId;
  const DepartmentDashboardPage({super.key, required this.departmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DepartmentDashboardCubit>()..loadAll(departmentId),
      child: _DashboardView(departmentId: departmentId),
    );
  }
}

class _DashboardView extends StatefulWidget {
  final String departmentId;
  const _DashboardView({required this.departmentId});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      body: BlocBuilder<DepartmentDashboardCubit, DepartmentDashboardState>(
        builder: (context, state) {
          if (state is DepartmentDashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DepartmentDashboardError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: AppDimensions.md),
                  Text(state.message),
                  const SizedBox(height: AppDimensions.md),
                  ElevatedButton(
                    onPressed: () => context
                        .read<DepartmentDashboardCubit>()
                        .loadAll(widget.departmentId),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is DepartmentDashboardLoaded) {
            return _buildDashboard(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DepartmentDashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(departmentId: widget.departmentId),
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Kalender Kelas'),
              Tab(text: 'Kursus'),
              Tab(text: 'Siswa'),
              Tab(text: 'Talent Pool'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CalendarTab(
                departmentId: widget.departmentId,
                batches: state.batches,
                isAssigning: state.isAssigningFacilitator,
              ),
              _CourseTab(courses: state.courses),
              _StudentTab(
                departmentId: widget.departmentId,
                students: state.students,
                currentFilter: state.studentFilter,
              ),
              _TalentPoolTab(entries: state.talentPool),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String departmentId;
  const _Header({required this.departmentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/departments'),
            tooltip: 'Kembali ke Departemen',
          ),
          const SizedBox(width: AppDimensions.sm),
          const Icon(Icons.business, color: AppColors.primary),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Dashboard Departemen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<DepartmentDashboardCubit>().loadAll(departmentId),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Tab ─────────────────────────────────────────────────────────────

class _CalendarTab extends StatefulWidget {
  final String departmentId;
  final List<DepartmentBatchEntity> batches;
  final bool isAssigning;
  const _CalendarTab(
      {required this.departmentId,
      required this.batches,
      required this.isAssigning});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  String _search = '';
  String _statusFilter = '';

  List<DepartmentBatchEntity> get _filtered {
    return widget.batches.where((b) {
      final matchSearch = _search.isEmpty ||
          b.batchName.toLowerCase().contains(_search) ||
          b.courseName.toLowerCase().contains(_search);
      final matchStatus =
          _statusFilter.isEmpty || b.batchStatus == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: AppDimensions.md),
          if (widget.isAssigning)
            const LinearProgressIndicator(color: AppColors.primary),
          Expanded(
            child: _filtered.isEmpty
                ? _emptyState('Belum ada kelas di departemen ini')
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) =>
                        _BatchCalendarCard(
                          batch: _filtered[i],
                          departmentId: widget.departmentId,
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari batch atau kursus...',
              prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: 10),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        _FilterChip(label: 'Semua', selected: _statusFilter.isEmpty, onTap: () => setState(() => _statusFilter = '')),
        const SizedBox(width: 6),
        _FilterChip(label: 'Akan Datang', selected: _statusFilter == 'upcoming', onTap: () => setState(() => _statusFilter = 'upcoming')),
        const SizedBox(width: 6),
        _FilterChip(label: 'Sedang Berjalan', selected: _statusFilter == 'ongoing', onTap: () => setState(() => _statusFilter = 'ongoing')),
        const SizedBox(width: 6),
        _FilterChip(label: 'Selesai', selected: _statusFilter == 'completed', onTap: () => setState(() => _statusFilter = 'completed')),
      ],
    );
  }
}

class _BatchCalendarCard extends StatelessWidget {
  final DepartmentBatchEntity batch;
  final String departmentId;
  const _BatchCalendarCard({required this.batch, required this.departmentId});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(batch.batchStatus);
    final statusLabel = _statusLabel(batch.batchStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            // Batch info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          batch.batchName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      _StatusBadge(label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    batch.courseName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${batch.startDate} — ${batch.endDate}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      const Icon(Icons.people_outline, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${batch.enrollmentCount}/${batch.maxParticipants} peserta',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            // Facilitator section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  batch.facilitatorName.isNotEmpty
                      ? batch.facilitatorName
                      : 'Belum ada fasilitator',
                  style: TextStyle(
                    fontSize: 12,
                    color: batch.facilitatorName.isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontStyle: batch.facilitatorName.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => _showAssignFacilitatorDialog(context),
                  icon: const Icon(Icons.person_add_alt, size: 14),
                  label: const Text('Assign', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignFacilitatorDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Fasilitator'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Batch: ${batch.batchName}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: AppDimensions.md),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'ID Fasilitator (User UUID)',
                  hintText: 'Kosongkan untuk unassign',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              context.read<DepartmentDashboardCubit>().assignFacilitator(
                    departmentId,
                    batch.batchId,
                    ctrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'upcoming':
        return AppColors.info;
      case 'ongoing':
        return AppColors.success;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'upcoming':
        return 'Akan Datang';
      case 'ongoing':
        return 'Sedang Berjalan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }
}

// ─── Course Tab ───────────────────────────────────────────────────────────────

class _CourseTab extends StatefulWidget {
  final List<DepartmentCourseEntity> courses;
  const _CourseTab({required this.courses});

  @override
  State<_CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<_CourseTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses
        .where((c) => _search.isEmpty || c.courseName.toLowerCase().contains(_search))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari kursus...',
                prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: filtered.isEmpty
                ? _emptyState('Belum ada kursus di departemen ini')
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _CourseCard(course: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final DepartmentCourseEntity course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: course.isActive
                  ? AppColors.primarySurface
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              Icons.school_outlined,
              color: course.isActive ? AppColors.primary : AppColors.textSecondary,
              size: AppDimensions.iconLg,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.courseName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: course.isActive
                            ? AppColors.successSurface
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Text(
                        course.isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                            fontSize: 11,
                            color: course.isActive
                                ? AppColors.success
                                : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (course.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      course.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${course.batchCount}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primary),
              ),
              const Text('Batch',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Student Tab ──────────────────────────────────────────────────────────────

class _StudentTab extends StatefulWidget {
  final String departmentId;
  final List<DepartmentStudentEntity> students;
  final String currentFilter;
  const _StudentTab(
      {required this.departmentId,
      required this.students,
      required this.currentFilter});

  @override
  State<_StudentTab> createState() => _StudentTabState();
}

class _StudentTabState extends State<_StudentTab> {
  String _search = '';

  List<DepartmentStudentEntity> get _filtered {
    return widget.students
        .where((s) =>
            _search.isEmpty ||
            s.studentName.toLowerCase().contains(_search) ||
            s.email.toLowerCase().contains(_search))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari siswa...',
                    prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              _FilterChip(
                label: 'Semua',
                selected: widget.currentFilter.isEmpty,
                onTap: () => context
                    .read<DepartmentDashboardCubit>()
                    .filterStudents(widget.departmentId, ''),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Aktif',
                selected: widget.currentFilter == 'active',
                onTap: () => context
                    .read<DepartmentDashboardCubit>()
                    .filterStudents(widget.departmentId, 'active'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Alumni',
                selected: widget.currentFilter == 'alumni',
                onTap: () => context
                    .read<DepartmentDashboardCubit>()
                    .filterStudents(widget.departmentId, 'alumni'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: _filtered.isEmpty
                ? _emptyState('Belum ada siswa di departemen ini')
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _StudentRow(student: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final DepartmentStudentEntity student;
  const _StudentRow({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppDimensions.avatarSm,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              student.initials,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                Text(
                  student.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(
                label: student.statusLabel,
                color: student.isActive ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                '${student.enrolledBatchCount} batch',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Talent Pool Tab ──────────────────────────────────────────────────────────

class _TalentPoolTab extends StatefulWidget {
  final List<DepartmentTalentPoolEntity> entries;
  const _TalentPoolTab({required this.entries});

  @override
  State<_TalentPoolTab> createState() => _TalentPoolTabState();
}

class _TalentPoolTabState extends State<_TalentPoolTab> {
  String _search = '';

  List<DepartmentTalentPoolEntity> get _filtered {
    return widget.entries
        .where((e) =>
            _search.isEmpty ||
            e.participantName.toLowerCase().contains(_search) ||
            e.participantEmail.toLowerCase().contains(_search))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari peserta...',
                prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: _filtered.isEmpty
                ? _emptyState('Belum ada anggota talent pool di departemen ini')
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _TalentPoolRow(entry: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TalentPoolRow extends StatelessWidget {
  final DepartmentTalentPoolEntity entry;
  const _TalentPoolRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(entry.status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppDimensions.avatarSm,
            backgroundColor: statusColor.withOpacity(0.15),
            child: Text(
              entry.initials,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.participantName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                Text(
                  entry.participantEmail,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(label: entry.statusLabel, color: statusColor),
              if (entry.testScore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Skor: ${entry.testScore!.toStringAsFixed(1)}',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'placed':
        return AppColors.primary;
      case 'inactive':
        return AppColors.textSecondary;
      default:
        return Colors.grey;
    }
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

Widget _emptyState(String message) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: AppDimensions.md),
        Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/course_entity.dart';
import '../cubit/course_cubit.dart';
import '../cubit/course_state.dart';

// ── Education stats data class ────────────────────────────────────────────────

class _EduStats {
  final int totalMasterCourses;
  final int activeBatches;
  final int upcomingBatches;
  final int totalEnrollments;

  const _EduStats({
    required this.totalMasterCourses,
    required this.activeBatches,
    required this.upcomingBatches,
    required this.totalEnrollments,
  });
}

// Halaman daftar MasterCourse — menampilkan semua kurikulum yang tersedia
class CoursePage extends StatelessWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseCubit>()..loadCourses(),
      child: const _CourseView(),
    );
  }
}

class _CourseView extends StatefulWidget {
  const _CourseView();

  @override
  State<_CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<_CourseView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'semua'; // semua | aktif | arsip
  String _fieldFilter = ''; // kosong = semua bidang
  int _currentPage = 0;
  static const _pageSize = 50;

  late final Future<_EduStats> _statsFuture = _loadStats();

  Future<_EduStats> _loadStats() async {
    final dio = getIt<ApiClient>().dio;
    int totalMasterCourses = 0;
    int activeBatches = 0;
    int upcomingBatches = 0;
    int totalEnrollments = 0;

    try {
      final results = await Future.wait([
        dio.get('/master-courses', queryParameters: {'limit': 1}),
        dio.get('/course-batches',
            queryParameters: {'status': 'ongoing', 'limit': 1}),
        dio.get('/enrollments', queryParameters: {'limit': 1}),
        dio.get('/course-batches',
            queryParameters: {'status': 'upcoming', 'limit': 1}),
      ]);

      final raw0 = results[0].data;
      totalMasterCourses = (raw0 is Map)
          ? ((raw0['meta']?['total'] ?? raw0['total'] ?? 0) as num).toInt()
          : 0;

      final raw1 = results[1].data;
      activeBatches = (raw1 is Map)
          ? ((raw1['meta']?['total'] ?? raw1['total'] ?? 0) as num).toInt()
          : 0;

      final raw2 = results[2].data;
      totalEnrollments = (raw2 is Map)
          ? ((raw2['meta']?['total'] ?? raw2['total'] ?? 0) as num).toInt()
          : 0;

      final raw3 = results[3].data;
      upcomingBatches = (raw3 is Map)
          ? ((raw3['meta']?['total'] ?? raw3['total'] ?? 0) as num).toInt()
          : 0;
    } catch (_) {
      // Gracefully default to 0 on any error
    }

    return _EduStats(
      totalMasterCourses: totalMasterCourses,
      activeBatches: activeBatches,
      upcomingBatches: upcomingBatches,
      totalEnrollments: totalEnrollments,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Filter lokal setelah data dimuat dari API
  List<CourseEntity> _filtered(List<CourseEntity> courses) {
    var list = courses;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.courseName.toLowerCase().contains(q) ||
              c.courseCode.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q))
          .toList();
    }

    if (_statusFilter == 'aktif') {
      list = list.where((c) => c.isActive).toList();
    } else if (_statusFilter == 'arsip') {
      list = list.where((c) => !c.isActive).toList();
    }

    if (_fieldFilter.isNotEmpty) {
      list = list.where((c) => c.field == _fieldFilter).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseCubit, CourseState>(
      listener: (context, state) {
        if (state is CourseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Page Header ──
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Pendidikan',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kelola kurikulum, batch, dan enrollment siswa VernonEdu',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Master Course'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // ── Section 2: KPI Stats Row ──
            FutureBuilder<_EduStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final stats = snapshot.data ??
                    const _EduStats(
                      totalMasterCourses: 0,
                      activeBatches: 0,
                      upcomingBatches: 0,
                      totalEnrollments: 0,
                    );
                final isLoading = snapshot.connectionState ==
                    ConnectionState.waiting;

                return Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: 'Total Master Course',
                        value: isLoading ? '...' : '${stats.totalMasterCourses}',
                        icon: Icons.menu_book_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: _KpiCard(
                        label: 'Batch Berjalan',
                        value: isLoading ? '...' : '${stats.activeBatches}',
                        icon: Icons.event_note_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: _KpiCard(
                        label: 'Batch Akan Datang',
                        value: isLoading ? '...' : '${stats.upcomingBatches}',
                        icon: Icons.upcoming_outlined,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: _KpiCard(
                        label: 'Total Enrollment',
                        value: isLoading ? '...' : '${stats.totalEnrollments}',
                        icon: Icons.how_to_reg_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Section 3: Quick Navigation Row ──
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickNavCard(
                    label: 'Master Course',
                    icon: Icons.menu_book_outlined,
                    route: '/curriculum',
                    active: true,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _QuickNavCard(
                    label: 'Batch Course',
                    icon: Icons.event_note_outlined,
                    route: '/course-batches',
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _QuickNavCard(
                    label: 'Enrollment',
                    icon: Icons.how_to_reg_outlined,
                    route: '/enrollments',
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _QuickNavCard(
                    label: 'Evaluasi',
                    icon: Icons.star_outline_rounded,
                    route: '/evaluations',
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _QuickNavCard(
                    label: 'Sertifikat',
                    icon: Icons.workspace_premium_outlined,
                    route: '/certificates',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            // ── Section 4: Master Course section title ──
            Text(
              'Master Course',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Statistics row per bidang (horizontal scroll) ──
            BlocBuilder<CourseCubit, CourseState>(
              builder: (context, state) {
                if (state is CourseLoaded) {
                  return _FieldStatsRow(
                    courses: state.courses,
                    selectedField: _fieldFilter,
                    onFieldTap: (f) => setState(() {
                      _fieldFilter = _fieldFilter == f ? '' : f;
                      _currentPage = 0;
                    }),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Filter Row ──
            _FiltersRow(
              searchCtrl: _searchCtrl,
              statusFilter: _statusFilter,
              fieldFilter: _fieldFilter,
              onSearchChanged: (v) => setState(() {
                _searchQuery = v;
                _currentPage = 0;
              }),
              onStatusChanged: (v) => setState(() {
                _statusFilter = v;
                _currentPage = 0;
              }),
              onFieldChanged: (v) => setState(() {
                _fieldFilter = v ?? '';
                _currentPage = 0;
              }),
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Grid Kursus ──
            Expanded(
              child: BlocBuilder<CourseCubit, CourseState>(
                builder: (context, state) {
                  if (state is CourseLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CourseError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: AppDimensions.md),
                          Text(state.message,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: AppDimensions.md),
                          FilledButton.icon(
                            onPressed: () =>
                                context.read<CourseCubit>().loadCourses(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is CourseLoaded) {
                    final all = _filtered(state.courses);
                    final totalPages =
                        (all.length / _pageSize).ceil().clamp(1, 999);
                    final paginated =
                        all.skip(_currentPage * _pageSize).take(_pageSize).toList();

                    if (all.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_outlined,
                                size: 64, color: AppColors.textHint),
                            const SizedBox(height: AppDimensions.md),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _fieldFilter.isNotEmpty
                                  ? 'Tidak ada course yang cocok dengan filter'
                                  : 'Belum ada master course',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Info jumlah + halaman
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppDimensions.sm),
                          child: Row(
                            children: [
                              Text(
                                '${all.length} course ditemukan',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                'Halaman ${_currentPage + 1} dari $totalPages',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),

                        // Grid cards course — tinggi seragam via childAspectRatio
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 520,
                              crossAxisSpacing: AppDimensions.md,
                              mainAxisSpacing: AppDimensions.md,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: paginated.length,
                            itemBuilder: (context, i) => _CourseCard(
                              course: paginated[i],
                              onTap: () =>
                                  context.go('/curriculum/${paginated[i].id}'),
                            ),
                          ),
                        ),

                        // Pagination
                        if (totalPages > 1)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppDimensions.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.outlined(
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                ...List.generate(
                                  totalPages.clamp(0, 7),
                                  (i) {
                                    final page = totalPages <= 7
                                        ? i
                                        : (i < 3
                                            ? i
                                            : i == 3
                                                ? _currentPage
                                                : totalPages - 3 + (i - 4));
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      child: _currentPage == page
                                          ? FilledButton(
                                              onPressed: () {},
                                              style: FilledButton.styleFrom(
                                                minimumSize:
                                                    const Size(36, 36),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Text('${page + 1}'),
                                            )
                                          : OutlinedButton(
                                              onPressed: () => setState(
                                                  () => _currentPage = page),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize:
                                                    const Size(36, 36),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Text('${page + 1}'),
                                            ),
                                    );
                                  },
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                IconButton.outlined(
                                  onPressed: _currentPage < totalPages - 1
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final cubit = context.read<CourseCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateCourseDialog(
        onCreated: (data) async => cubit.createCourse(data),
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, size: AppDimensions.iconMd, color: color),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

// ── Quick Nav Card ────────────────────────────────────────────────────────────

class _QuickNavCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final String route;
  final bool active;

  const _QuickNavCard({
    required this.label,
    required this.icon,
    required this.route,
    this.active = false,
  });

  @override
  State<_QuickNavCard> createState() => _QuickNavCardState();
}

class _QuickNavCardState extends State<_QuickNavCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.active || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 160,
          height: 72,
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.primarySurface
                : _isHovered
                    ? AppColors.primarySurface.withValues(alpha: 0.5)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isHighlighted ? AppColors.primary : AppColors.border,
              width: isHighlighted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: AppDimensions.iconMd,
                color: isHighlighted
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Field Stats Row ───────────────────────────────────────────────────────────

class _FieldStatsRow extends StatelessWidget {
  final List<CourseEntity> courses;
  final String selectedField;
  final void Function(String) onFieldTap;

  const _FieldStatsRow({
    required this.courses,
    required this.selectedField,
    required this.onFieldTap,
  });

  Color _colorForField(String field) => switch (field) {
        'coding' => AppColors.primary,
        'culinary' => AppColors.warning,
        'barber' => AppColors.roleDeptLeader,
        'public_speaking' => AppColors.info,
        'entrepreneurship' => AppColors.roleCourseOwner,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final fields = <String>{};
    for (final c in courses) {
      if (c.field.isNotEmpty) fields.add(c.field);
    }

    final allActive = courses.where((c) => c.isActive).length;
    final allInactive = courses.length - allActive;

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Card "Semua Bidang"
          _FieldStatCard(
            label: 'Semua Bidang',
            activeCount: allActive,
            inactiveCount: allInactive,
            color: AppColors.primary,
            selected: selectedField.isEmpty,
            onTap: () => onFieldTap(''),
          ),
          const SizedBox(width: AppDimensions.sm),
          // Card per bidang
          ...fields.map((f) {
            final fieldCourses = courses.where((c) => c.field == f).toList();
            final active = fieldCourses.where((c) => c.isActive).length;
            final inactive = fieldCourses.length - active;
            final label = CourseField.fromString(f).label;
            return Padding(
              padding: const EdgeInsets.only(right: AppDimensions.sm),
              child: _FieldStatCard(
                label: label,
                activeCount: active,
                inactiveCount: inactive,
                color: _colorForField(f),
                selected: selectedField == f,
                onTap: () => onFieldTap(f),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FieldStatCard extends StatelessWidget {
  final String label;
  final int activeCount;
  final int inactiveCount;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FieldStatCard({
    required this.label,
    required this.activeCount,
    required this.inactiveCount,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 190,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md, vertical: AppDimensions.sm),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Aktif
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '$activeCount Aktif',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.success),
                ),
                const SizedBox(width: AppDimensions.sm),
                // Tidak aktif
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.textHint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '$inactiveCount Nonaktif',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filters Row ───────────────────────────────────────────────────────────────

class _FiltersRow extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String statusFilter;
  final String fieldFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onFieldChanged;

  const _FiltersRow({
    required this.searchCtrl,
    required this.statusFilter,
    required this.fieldFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Search text field
        SizedBox(
          width: 260,
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Nama / kode course...',
              prefixIcon:
                  const Icon(Icons.search, size: AppDimensions.iconMd),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: AppDimensions.iconMd),
                      onPressed: () {
                        searchCtrl.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.md),

        // Dropdown status
        DropdownButton<String>(
          value: statusFilter,
          underline: const SizedBox.shrink(),
          style: const TextStyle(
              fontSize: 13, color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: 'semua', child: Text('Semua')),
            DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
            DropdownMenuItem(
                value: 'arsip', child: Text('Tidak Aktif')),
          ],
          onChanged: (v) {
            if (v != null) onStatusChanged(v);
          },
        ),
        const SizedBox(width: AppDimensions.md),

        // Separator
        Container(width: 1, height: 20, color: AppColors.border),
        const SizedBox(width: AppDimensions.md),

        // Dropdown bidang
        DropdownButton<String?>(
          value: fieldFilter.isEmpty ? null : fieldFilter,
          hint: const Text('Semua Bidang',
              style: TextStyle(fontSize: 13)),
          underline: const SizedBox.shrink(),
          style: const TextStyle(
              fontSize: 13, color: AppColors.textPrimary),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Semua Bidang'),
            ),
            ...CourseField.values
                .where((f) => f != CourseField.other)
                .map(
                  (f) => DropdownMenuItem<String?>(
                    value: f == CourseField.publicSpeaking
                        ? 'public_speaking'
                        : f.name,
                    child: Text(f.label),
                  ),
                ),
            const DropdownMenuItem<String?>(
              value: 'other',
              child: Text('Lainnya'),
            ),
          ],
          onChanged: onFieldChanged,
        ),
      ],
    );
  }
}

// ── Course Card ───────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  Color _fieldColor() => switch (course.field) {
        'coding' => AppColors.primary,
        'culinary' => AppColors.warning,
        'barber' => AppColors.roleDeptLeader,
        'public_speaking' => AppColors.info,
        'entrepreneurship' => AppColors.roleCourseOwner,
        _ => AppColors.textSecondary,
      };

  String _fieldLabel() => CourseField.fromString(course.field).label;

  @override
  Widget build(BuildContext context) {
    final fieldColor = _fieldColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris atas: kode course | Spacer | badge status ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      course.courseCode.isNotEmpty
                          ? course.courseCode
                          : '—',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: course.isActive
                          ? AppColors.successSurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusCircle),
                    ),
                    child: Text(
                      course.isActive ? 'Aktif' : 'Arsip',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: course.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),

              // ── Nama course ──
              Text(
                course.courseName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.xs),

              // ── Badge bidang | Spacer | Harga placeholder ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: fieldColor.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      _fieldLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fieldColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),

              // ── Divider ──
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.sm),

              // ── Stats 3 kolom: Batch Berjalan | Akan Datang | Selesai ──
              const Row(
                children: [
                  Expanded(
                    child: _StatItem(label: 'Berjalan', value: '0'),
                  ),
                  Expanded(
                    child: _StatItem(label: 'Akan Datang', value: '0'),
                  ),
                  Expanded(
                    child: _StatItem(label: 'Selesai', value: '0'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),

              // ── Deskripsi singkat ──
              Expanded(
                child: Text(
                  course.description.isEmpty
                      ? 'Belum ada deskripsi untuk course ini.'
                      : course.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget stat kecil di dalam card
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, color: AppColors.textHint),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Dialog Tambah Course ──────────────────────────────────────────────────────

class _CreateCourseDialog extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic> data) onCreated;

  const _CreateCourseDialog({required this.onCreated});

  @override
  State<_CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<_CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _competencyCtrl = TextEditingController();
  String _selectedField = 'coding';
  final List<String> _competencies = [];
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _competencyCtrl.dispose();
    super.dispose();
  }

  void _addCompetency() {
    final val = _competencyCtrl.text.trim();
    if (val.isNotEmpty && !_competencies.contains(val)) {
      setState(() {
        _competencies.add(val);
        _competencyCtrl.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final success = await widget.onCreated({
      'course_code': _codeCtrl.text.trim(),
      'course_name': _nameCtrl.text.trim(),
      'field': _selectedField,
      'description': _descCtrl.text.trim(),
      'core_competencies': _competencies,
      'status': 'active',
    });
    if (mounted) {
      setState(() => _loading = false);
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Master Course',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppDimensions.md),

                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Kode Course',
                      hintText: 'Contoh: COD-001'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Kode course wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),

                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Course'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama course wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),

                DropdownButtonFormField<String>(
                  initialValue: _selectedField,
                  decoration:
                      const InputDecoration(labelText: 'Bidang Kursus'),
                  items: CourseField.values
                      .map((f) => DropdownMenuItem(
                            value: f == CourseField.publicSpeaking
                                ? 'public_speaking'
                                : f.name,
                            child: Text(f.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedField = v ?? 'coding'),
                ),
                const SizedBox(height: AppDimensions.sm),

                TextFormField(
                  controller: _descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                const SizedBox(height: AppDimensions.sm),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _competencyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tambah Kompetensi Inti',
                          hintText: 'Ketik lalu tekan tambah',
                        ),
                        onSubmitted: (_) => _addCompetency(),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    IconButton.outlined(
                      onPressed: _addCompetency,
                      icon: const Icon(Icons.add),
                      tooltip: 'Tambah kompetensi',
                    ),
                  ],
                ),

                if (_competencies.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _competencies
                        .map((c) => Chip(
                              label: Text(c,
                                  style: const TextStyle(fontSize: 12)),
                              onDeleted: () =>
                                  setState(() => _competencies.remove(c)),
                              deleteIconColor: AppColors.textSecondary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: AppDimensions.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

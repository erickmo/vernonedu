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
import '../../../course_batch/presentation/cubit/course_batch_cubit.dart';
import '../../../course_batch/presentation/cubit/course_batch_state.dart';
import '../../../course_batch/domain/entities/course_batch_entity.dart';

// ── Stats ─────────────────────────────────────────────────────────────────────

class _EduStats {
  final int totalCourses;
  final int activeBatches;
  final int totalEnrolled;
  final int upcomingBatches;

  const _EduStats({
    required this.totalCourses,
    required this.activeBatches,
    required this.totalEnrolled,
    required this.upcomingBatches,
  });
}

// ── Education Page ─────────────────────────────────────────────────────────────

/// Halaman utama Manajemen Edukasi — menampilkan daftar Course dan Course Batch
/// dalam dua tab, dengan statistik di bagian atas.
class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CourseCubit>()..loadCourses()),
        BlocProvider(create: (_) => getIt<CourseBatchCubit>()..loadBatches()),
      ],
      child: const _EducationView(),
    );
  }
}

class _EducationView extends StatefulWidget {
  const _EducationView();

  @override
  State<_EducationView> createState() => _EducationViewState();
}

class _EducationViewState extends State<_EducationView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Course tab filters
  final _courseSearchCtrl = TextEditingController();
  String _courseSearch = '';
  String _courseStatus = '';

  // Batch tab filters
  final _batchSearchCtrl = TextEditingController();
  String _batchSearch = '';
  String _batchStatus = '';

  // Stats
  late final Future<_EduStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _statsFuture = _loadStats();
  }

  Future<_EduStats> _loadStats() async {
    final dio = getIt<ApiClient>().dio;
    int totalCourses = 0;
    int activeBatches = 0;
    int totalEnrolled = 0;
    int upcomingBatches = 0;
    try {
      final results = await Future.wait([
        dio.get('/curriculum/courses', queryParameters: {'limit': 1}),
        dio.get('/course-batches',
            queryParameters: {'status': 'ongoing', 'limit': 1}),
        dio.get('/enrollments', queryParameters: {'limit': 1}),
        dio.get('/course-batches',
            queryParameters: {'status': 'upcoming', 'limit': 1}),
      ]);
      totalCourses = _extractTotal(results[0].data);
      activeBatches = _extractTotal(results[1].data);
      totalEnrolled = _extractTotal(results[2].data);
      upcomingBatches = _extractTotal(results[3].data);
    } catch (_) {}
    return _EduStats(
      totalCourses: totalCourses,
      activeBatches: activeBatches,
      totalEnrolled: totalEnrolled,
      upcomingBatches: upcomingBatches,
    );
  }

  int _extractTotal(dynamic raw) {
    if (raw is! Map) return 0;
    return ((raw['meta']?['total'] ?? raw['total'] ?? 0) as num).toInt();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseSearchCtrl.dispose();
    _batchSearchCtrl.dispose();
    super.dispose();
  }

  List<CourseEntity> _filteredCourses(List<CourseEntity> courses) {
    var list = courses;
    if (_courseSearch.isNotEmpty) {
      final q = _courseSearch.toLowerCase();
      list = list
          .where((c) =>
              c.courseName.toLowerCase().contains(q) ||
              c.courseCode.toLowerCase().contains(q))
          .toList();
    }
    if (_courseStatus == 'active') {
      list = list.where((c) => c.isActive).toList();
    } else if (_courseStatus == 'archived') {
      list = list.where((c) => !c.isActive).toList();
    }
    return list;
  }

  List<CourseBatchEntity> _filteredBatches(List<CourseBatchEntity> batches) {
    var list = batches;
    if (_batchSearch.isNotEmpty) {
      final q = _batchSearch.toLowerCase();
      list = list
          .where((b) =>
              b.masterCourseName.toLowerCase().contains(q) ||
              b.code.toLowerCase().contains(q))
          .toList();
    }
    if (_batchStatus.isNotEmpty) {
      list = list.where((b) => b.status == _batchStatus).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppDimensions.lg),
          _buildStats(),
          const SizedBox(height: AppDimensions.lg),
          _buildTabBar(),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCourseTab(context),
                _buildBatchTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manajemen Edukasi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Kelola Course, Course Batch, Module dan Enrollment',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return FutureBuilder<_EduStats>(
      future: _statsFuture,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final s = snap.data ??
            const _EduStats(
                totalCourses: 0,
                activeBatches: 0,
                totalEnrolled: 0,
                upcomingBatches: 0);
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Course',
                value: loading ? '...' : '${s.totalCourses}',
                icon: Icons.menu_book_outlined,
                color: AppColors.primary,
                surfaceColor: AppColors.primarySurface,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _StatCard(
                label: 'Batch Berjalan',
                value: loading ? '...' : '${s.activeBatches}',
                subtitle: loading ? '' : '${s.totalEnrolled} siswa terdaftar',
                icon: Icons.event_note_outlined,
                color: AppColors.secondary,
                surfaceColor: AppColors.successSurface,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _StatCard(
                label: 'Batch Mendatang',
                value: loading ? '...' : '${s.upcomingBatches}',
                icon: Icons.upcoming_outlined,
                color: AppColors.warning,
                surfaceColor: AppColors.warningSurface,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd - 1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Course'),
          Tab(text: 'Course Batch'),
        ],
      ),
    );
  }

  Widget _buildCourseTab(BuildContext context) {
    return BlocBuilder<CourseCubit, CourseState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildCourseFilters(context),
            const SizedBox(height: AppDimensions.md),
            Expanded(child: _buildCourseContent(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildCourseFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: AppDimensions.buttonHeight,
            child: TextField(
              controller: _courseSearchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari course...',
                prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              ),
              onChanged: (v) => setState(() => _courseSearch = v),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        SizedBox(
          height: AppDimensions.buttonHeight,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _courseStatus,
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua Status')),
                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                DropdownMenuItem(value: 'archived', child: Text('Tidak Aktif')),
              ],
              onChanged: (v) => setState(() => _courseStatus = v ?? ''),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            ),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: AppDimensions.iconMd),
          label: const Text('Tambah Course'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            fixedSize: const Size.fromHeight(AppDimensions.buttonHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseContent(BuildContext context, CourseState state) {
    if (state is CourseLoading || state is CourseInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is CourseError) {
      return _ErrorRetry(
        message: state.message,
        onRetry: () => context.read<CourseCubit>().loadCourses(),
      );
    }
    if (state is CourseLoaded) {
      final filtered = _filteredCourses(state.courses);
      if (filtered.isEmpty) {
        return const _EmptyState(
          icon: Icons.menu_book_outlined,
          message: 'Belum ada course ditemukan',
        );
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 440,
          crossAxisSpacing: AppDimensions.md,
          mainAxisSpacing: AppDimensions.md,
          childAspectRatio: 1.5,
        ),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _CourseCard(
          course: filtered[i],
          onTap: () => context.push('/curriculum/${filtered[i].id}'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBatchTab(BuildContext context) {
    return BlocBuilder<CourseBatchCubit, CourseBatchState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildBatchFilters(context),
            const SizedBox(height: AppDimensions.md),
            Expanded(child: _buildBatchContent(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBatchFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: AppDimensions.buttonHeight,
            child: TextField(
              controller: _batchSearchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari batch...',
                prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              ),
              onChanged: (v) => setState(() => _batchSearch = v),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        SizedBox(
          height: AppDimensions.buttonHeight,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _batchStatus,
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua Status')),
                DropdownMenuItem(value: 'ongoing', child: Text('Berjalan')),
                DropdownMenuItem(
                    value: 'upcoming', child: Text('Akan Datang')),
                DropdownMenuItem(value: 'completed', child: Text('Selesai')),
              ],
              onChanged: (v) => setState(() => _batchStatus = v ?? ''),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            ),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: AppDimensions.iconMd),
          label: const Text('Tambah Course Batch'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            fixedSize: const Size.fromHeight(AppDimensions.buttonHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchContent(BuildContext context, CourseBatchState state) {
    if (state is CourseBatchLoading || state is CourseBatchInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is CourseBatchError) {
      return _ErrorRetry(
        message: state.message,
        onRetry: () => context.read<CourseBatchCubit>().loadBatches(),
      );
    }
    if (state is CourseBatchLoaded) {
      final filtered = _filteredBatches(state.batches);
      if (filtered.isEmpty) {
        return const _EmptyState(
          icon: Icons.event_note_outlined,
          message: 'Belum ada course batch ditemukan',
        );
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 440,
          crossAxisSpacing: AppDimensions.md,
          mainAxisSpacing: AppDimensions.md,
          childAspectRatio: 1.8,
        ),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _CourseBatchCard(
          batch: filtered[i],
          onTap: () =>
              context.push('/course-batches/${filtered[i].id}'),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color surfaceColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconLg),
          ),
          const SizedBox(width: AppDimensions.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Course Card ───────────────────────────────────────────────────────────────

class _CourseCard extends StatefulWidget {
  final CourseEntity course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: _hovered ? AppColors.primaryLight : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    _StatusChip(isActive: c.isActive),
                  ],
                ),
                const SizedBox(height: AppDimensions.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    c.courseCode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  c.description.isEmpty ? 'Tidak ada deskripsi' : c.description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  'Bidang: ${CourseField.fromString(c.field).label}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Course Batch Card ─────────────────────────────────────────────────────────

class _CourseBatchCard extends StatefulWidget {
  final CourseBatchEntity batch;
  final VoidCallback onTap;

  const _CourseBatchCard({required this.batch, required this.onTap});

  @override
  State<_CourseBatchCard> createState() => _CourseBatchCardState();
}

class _CourseBatchCardState extends State<_CourseBatchCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: _hovered ? AppColors.primaryLight : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.masterCourseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _BatchStatusChip(status: b.status),
                  ],
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  b.code,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Siswa: ${b.totalEnrolled} / ${b.minParticipants}-${b.maxParticipants}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (b.price != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Harga: Rp ${_formatNumber(b.price!.toInt())}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int n) => n
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// ── Status Chips ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Tidak Aktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _BatchStatusChip extends StatelessWidget {
  final String status;
  const _BatchStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'ongoing' => ('Berjalan', AppColors.success, AppColors.successSurface),
      'upcoming' => ('Akan Datang', AppColors.info, AppColors.infoSurface),
      'completed' => ('Selesai', AppColors.textSecondary, AppColors.surfaceVariant),
      'cancelled' => ('Dibatalkan', AppColors.error, AppColors.errorSurface),
      _ => (status, AppColors.textSecondary, AppColors.surfaceVariant),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text(message,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

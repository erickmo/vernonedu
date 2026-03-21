import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/batch_detail_entity.dart';
import '../../domain/entities/batch_entity.dart';
import '../../domain/entities/enrolled_student_entity.dart';
import '../cubit/batch_detail_cubit.dart';
import '../cubit/batch_detail_state.dart';

class BatchDetailPage extends StatelessWidget {
  final String batchId;

  const BatchDetailPage({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BatchDetailCubit>()..loadDetail(batchId),
      child: _BatchDetailView(batchId: batchId),
    );
  }
}

class _BatchDetailView extends StatelessWidget {
  final String batchId;

  const _BatchDetailView({required this.batchId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BatchDetailCubit, BatchDetailState>(
      builder: (context, state) {
        if (state is BatchDetailLoading || state is BatchDetailInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is BatchDetailError) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.batchDetail)),
            body: ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<BatchDetailCubit>().loadDetail(batchId),
            ),
          );
        }
        if (state is BatchDetailLoaded) {
          return _BatchDetailContent(
            detail: state.detail,
            batchId: batchId,
            isAssigning: state.isAssigning,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BatchDetailContent extends StatefulWidget {
  final BatchDetailEntity detail;
  final String batchId;
  final bool isAssigning;

  const _BatchDetailContent({
    required this.detail,
    required this.batchId,
    required this.isAssigning,
  });

  @override
  State<_BatchDetailContent> createState() => _BatchDetailContentState();
}

class _BatchDetailContentState extends State<_BatchDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.detail.batch;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildSliverAppBar(context, batch),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _StudentsTab(students: widget.detail.students),
                  _ModulesTab(modules: widget.detail.modules),
                  _InfoTab(
                    batch: batch,
                    batchId: widget.batchId,
                    isAssigning: widget.isAssigning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, BatchEntity batch) =>
      SliverAppBar(
        expandedHeight: 160,
        pinned: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        flexibleSpace: FlexibleSpaceBar(
          background: _buildHeaderBg(context, batch),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(
            color: AppColors.surface,
            height: 4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined,
                color: AppColors.textOnPrimary),
            tooltip: AppStrings.takeAttendance,
            onPressed: () =>
                context.push('/batches/${widget.batchId}/attendance'),
          ),
        ],
      );

  Widget _buildHeaderBg(BuildContext context, BatchEntity batch) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.xxl + AppDimensions.md,
          AppDimensions.pagePadding,
          AppDimensions.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              batch.masterCourseName,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.tag_rounded,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(batch.code,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(width: AppDimensions.md),
                const Icon(Icons.people_outlined,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text('${batch.totalEnrolled} siswa',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Siswa'),
            Tab(text: 'Modul'),
            Tab(text: 'Info'),
          ],
        ),
      );
}

// ─── Students Tab ─────────────────────────────────────────────────────────────

class _StudentsTab extends StatelessWidget {
  final List<EnrolledStudentEntity> students;

  const _StudentsTab({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const EmptyView(
        icon: Icons.people_outline,
        message: 'Belum ada siswa terdaftar',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      itemCount: students.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.xs),
      itemBuilder: (_, i) => _StudentTile(student: students[i]),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final EnrolledStudentEntity student;

  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppDimensions.avatarSm / 2,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              student.initials,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.studentName,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(student.studentCode,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (student.attendanceRate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(student.attendanceRate! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: student.attendanceRate! >= 0.75
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const Text('Hadir',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Modules Tab ──────────────────────────────────────────────────────────────

class _ModulesTab extends StatelessWidget {
  final List<BatchModuleEntity> modules;

  const _ModulesTab({required this.modules});

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return const EmptyView(
        icon: Icons.menu_book_outlined,
        message: 'Belum ada modul',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      itemCount: modules.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.xs),
      itemBuilder: (_, i) => _ModuleTile(module: modules[i], index: i),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final BatchModuleEntity module;
  final int index;

  const _ModuleTile({required this.module, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: module.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: module.isCompleted
                  ? AppColors.successSurface
                  : AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: module.isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.success, size: 16)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(module.title,
                style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

// ─── Info Tab ─────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final BatchEntity batch;
  final String batchId;
  final bool isAssigning;

  const _InfoTab({
    required this.batch,
    required this.batchId,
    required this.isAssigning,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSection(
            title: 'Informasi Kelas',
            children: [
              _InfoRow(label: AppStrings.batchCode, value: batch.code),
              _InfoRow(label: AppStrings.batchStatus, value: batch.statusLabel),
              _InfoRow(
                label: 'Mulai',
                value: DateUtil.toDisplay(batch.startDate),
              ),
              _InfoRow(
                label: 'Selesai',
                value: DateUtil.toDisplay(batch.endDate),
              ),
              if (batch.location != null)
                _InfoRow(label: 'Lokasi', value: batch.location!),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildFacilitatorSection(context),
        ],
      ),
    );
  }

  Widget _buildFacilitatorSection(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final canAssign = authState is AuthAuthenticated &&
        authState.user.canAssignFacilitator;

    return _InfoSection(
      title: AppStrings.facilitator,
      action: canAssign
          ? GestureDetector(
              onTap: () => context.push(
                '/batches/$batchId/assign-facilitator',
                extra: batch,
              ),
              child: Text(
                batch.facilitatorName != null
                    ? AppStrings.changeFacilitator
                    : AppStrings.assignFacilitator,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      children: [
        if (batch.facilitatorName != null)
          _InfoRow(label: 'Nama', value: batch.facilitatorName!)
        else
          const Text(
            AppStrings.noFacilitator,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? action;

  const _InfoSection({
    required this.title,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

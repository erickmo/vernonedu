import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_util.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../batch/domain/entities/batch_entity.dart';
import '../../../batch/presentation/cubit/batch_list_cubit.dart';
import '../../../batch/presentation/cubit/batch_list_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BatchListCubit, BatchListState>(
      builder: (context, state) {
        if (state is BatchListInitial) {
          context.read<BatchListCubit>().loadBatches();
        }
        return const _HomeView();
      },
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<BatchListCubit>().loadBatches(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildStatsRow(context)),
              SliverToBoxAdapter(child: _buildActiveBatchesSection(context)),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.user.name : '';
        final role = state is AuthAuthenticated ? state.user.roleLabel : '';
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePadding,
            AppDimensions.lg,
            AppDimensions.pagePadding,
            AppDimensions.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateUtil.greeting(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        _RoleBadge(role: role),
                      ],
                    ),
                  ),
                  _buildAvatar(context, state),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              _buildTodayCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, AuthState state) {
    final initials = state is AuthAuthenticated ? state.user.initials : '?';
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: Container(
        width: AppDimensions.avatarLg,
        height: AppDimensions.avatarLg,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryLight, width: 2),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.textOnPrimary,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.sm),
            Text(
              DateUtil.toDisplayWithDay(DateTime.now()),
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatsRow(BuildContext context) {
    return BlocBuilder<BatchListCubit, BatchListState>(
      builder: (context, state) {
        final batches =
            state is BatchListLoaded ? state.batches : <BatchEntity>[];
        final active = batches.where((b) => b.isActive).length;
        final students = batches.fold<int>(0, (sum, b) => sum + b.totalEnrolled);

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding),
          child: Row(
            children: [
              _StatCard(
                label: AppStrings.totalBatches,
                value: '${batches.length}',
                icon: Icons.class_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.sm),
              _StatCard(
                label: AppStrings.activeSessions,
                value: '$active',
                icon: Icons.play_circle_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.sm),
              _StatCard(
                label: AppStrings.totalStudents,
                value: '$students',
                icon: Icons.people_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveBatchesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePadding,
        AppDimensions.lg,
        AppDimensions.pagePadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelas Aktif',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: () => context.go('/batches'),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          BlocBuilder<BatchListCubit, BatchListState>(
            builder: (context, state) {
              if (state is BatchListLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is BatchListError) {
                return Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                );
              }
              if (state is BatchListLoaded) {
                final active = state.batches.where((b) => b.isActive).toList();
                if (active.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        AppStrings.noBatches,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return Column(
                  children: active
                      .take(3)
                      .map((b) => _HomeBatchCard(
                            batch: b,
                            onTap: () =>
                                context.push('/batches/${b.id}'),
                          ))
                      .toList(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBatchCard extends StatelessWidget {
  final BatchEntity batch;
  final VoidCallback onTap;

  const _HomeBatchCard({required this.batch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.class_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.masterCourseName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${batch.code} · ${batch.totalEnrolled} ${AppStrings.studentsEnrolled}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

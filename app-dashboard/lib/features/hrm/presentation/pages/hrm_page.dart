import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/sdm_entity.dart';
import '../cubit/sdm_list_cubit.dart';
import '../cubit/sdm_list_state.dart';
import '../widgets/sdm_card.dart';

/// Halaman daftar SDM — menampilkan semua sumber daya manusia beserta filter
/// dan statistik ringkasan.
class HrmPage extends StatelessWidget {
  const HrmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SdmListCubit>()..loadSdmList(),
      child: const _HrmView(),
    );
  }
}

class _HrmView extends StatefulWidget {
  const _HrmView();

  @override
  State<_HrmView> createState() => _HrmViewState();
}

class _HrmViewState extends State<_HrmView> {
  String _searchQuery = '';
  SdmRole? _selectedRole;
  SdmStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SdmListCubit, SdmListState>(
      listener: (context, state) {
        if (state is SdmListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppDimensions.lg),
            _buildSummaryCards(context),
            const SizedBox(height: AppDimensions.lg),
            _buildSearchAndFilter(context),
            const SizedBox(height: AppDimensions.md),
            _buildList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.sdmPageTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  AppStrings.sdmPageSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildSummaryCards(BuildContext context) {
    return BlocBuilder<SdmListCubit, SdmListState>(
      builder: (context, state) {
        if (state is! SdmListLoaded) {
          return const Row(
            children: [
              Expanded(child: _SummarySkeleton()),
              SizedBox(width: AppDimensions.md),
              Expanded(child: _SummarySkeleton()),
              SizedBox(width: AppDimensions.md),
              Expanded(child: _SummarySkeleton()),
              SizedBox(width: AppDimensions.md),
              Expanded(child: _SummarySkeleton()),
            ],
          );
        }
        final list = state.sdmList;
        final active =
            list.where((s) => s.status == SdmStatus.active).length;
        final creators = list
            .where((s) => s.role == SdmRole.courseCreator)
            .length;
        final facilitators =
            list.where((s) => s.role == SdmRole.facilitator).length;

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.badge_outlined,
                value: '${list.length}',
                label: AppStrings.sdmSummaryTotal,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _SummaryCard(
                icon: Icons.check_circle_outline,
                value: '$active',
                label: AppStrings.sdmSummaryActive,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _SummaryCard(
                icon: Icons.create_outlined,
                value: '$creators',
                label: AppStrings.sdmSummaryCreators,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _SummaryCard(
                icon: Icons.group_outlined,
                value: '$facilitators',
                label: AppStrings.sdmSummaryMentors,
                color: AppColors.info,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) => Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: AppStrings.sdmSearchHint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: AppDimensions.iconMd,
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          _buildRoleFilter(context),
          const SizedBox(width: AppDimensions.sm),
          _buildStatusFilter(context),
        ],
      );

  Widget _buildRoleFilter(BuildContext context) => PopupMenuButton<SdmRole?>(
        onSelected: (v) => setState(() => _selectedRole = v),
        tooltip: AppStrings.sdmFilterRole,
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: null,
            child: Text('Semua Peran'),
          ),
          ...SdmRole.values.map(
            (r) => PopupMenuItem(value: r, child: Text(r.label)),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: _selectedRole != null
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                size: AppDimensions.iconSm,
                color: _selectedRole != null
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              const SizedBox(width: AppDimensions.xs),
              Text(
                _selectedRole?.label ?? AppStrings.sdmFilterRole,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _selectedRole != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: AppDimensions.xs),
              const Icon(
                Icons.arrow_drop_down,
                size: AppDimensions.iconMd,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      );

  Widget _buildStatusFilter(BuildContext context) =>
      PopupMenuButton<SdmStatus?>(
        onSelected: (v) => setState(() => _selectedStatus = v),
        tooltip: AppStrings.sdmFilterStatus,
        itemBuilder: (_) => [
          const PopupMenuItem(value: null, child: Text('Semua Status')),
          const PopupMenuItem(
              value: SdmStatus.active, child: Text('Aktif')),
          const PopupMenuItem(
              value: SdmStatus.inactive, child: Text('Tidak Aktif')),
          const PopupMenuItem(
              value: SdmStatus.onLeave, child: Text('Cuti')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: _selectedStatus != null
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                size: AppDimensions.iconSm,
                color: _selectedStatus != null
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              const SizedBox(width: AppDimensions.xs),
              Text(
                _selectedStatus != null
                    ? _statusLabel(_selectedStatus!)
                    : AppStrings.sdmFilterStatus,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _selectedStatus != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: AppDimensions.xs),
              const Icon(
                Icons.arrow_drop_down,
                size: AppDimensions.iconMd,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      );

  Widget _buildList(BuildContext context) {
    return BlocBuilder<SdmListCubit, SdmListState>(
      builder: (context, state) {
        if (state is SdmListLoading || state is SdmListInitial) {
          return _buildLoadingList();
        }
        if (state is SdmListError) {
          return _buildErrorState(context, state.message);
        }
        if (state is SdmListLoaded) {
          final filtered = _applyFilters(state.sdmList);
          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }
          return Column(
            children: filtered
                .map((sdm) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: SdmCard(
                        sdm: sdm,
                        onTap: () => context.push('/hrm/${sdm.id}'),
                      ),
                    ))
                .toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingList() => Column(
        children: List.generate(
          5,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.sm),
            child: _CardSkeleton(),
          ),
        ),
      );

  Widget _buildErrorState(BuildContext context, String message) => Container(
        padding: const EdgeInsets.all(AppDimensions.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppDimensions.md),
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<SdmListCubit>().loadSdmList(),
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimensions.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                _searchQuery.isNotEmpty
                    ? AppStrings.emptySearch
                    : AppStrings.emptyData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );

  List<SdmEntity> _applyFilters(List<SdmEntity> list) {
    return list.where((sdm) {
      final matchQuery = _searchQuery.isEmpty ||
          sdm.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sdm.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchRole = _selectedRole == null || sdm.role == _selectedRole;
      final matchStatus =
          _selectedStatus == null || sdm.status == _selectedStatus;
      return matchQuery && matchRole && matchStatus;
    }).toList();
  }

  String _statusLabel(SdmStatus s) {
    switch (s) {
      case SdmStatus.active:
        return 'Aktif';
      case SdmStatus.inactive:
        return 'Tidak Aktif';
      case SdmStatus.onLeave:
        return 'Cuti';
    }
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconMd),
          ),
          const SizedBox(width: AppDimensions.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      );
}

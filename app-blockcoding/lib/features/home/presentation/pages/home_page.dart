import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vernonedu_blockcoding/core/constants/app_colors.dart';
import 'package:vernonedu_blockcoding/core/constants/app_dimensions.dart';
import 'package:vernonedu_blockcoding/core/constants/app_strings.dart';
import 'package:vernonedu_blockcoding/core/di/injection.dart';
import 'package:vernonedu_blockcoding/features/home/domain/entities/challenge.dart';
import 'package:vernonedu_blockcoding/features/home/presentation/bloc/home_cubit.dart';
import 'package:vernonedu_blockcoding/features/home/presentation/bloc/home_state.dart';

/// Halaman beranda — menampilkan kategori challenge dan progress.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            HomeError(:final message) => _buildError(context, message),
            HomeLoaded() => _buildContent(context, state),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ElevatedButton(
            onPressed: () => context.read<HomeCubit>().load(),
            child: const Text(AppStrings.back),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeLoaded state) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, state),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // — Free coding button
              _buildFreeCodingCard(context),
              const SizedBox(height: AppDimensions.spacingL),

              // — Section title
              const Text(
                AppStrings.homeChallenges,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
            ]),
          ),
        ),

        // — Categories
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = state.categories[index];
                return _CategorySection(
                  category: category,
                  completedIds: state.completedChallengeIds,
                );
              },
              childCount: state.categories.length,
            ),
          ),
        ),

        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppDimensions.spacingXxl),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, HomeLoaded state) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(state),
      ),
    );
  }

  Widget _buildHeader(HomeLoaded state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceVariant],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — App branding
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: const Icon(
                      Icons.widgets_rounded,
                      color: AppColors.primary,
                      size: AppDimensions.iconL,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'VernonEdu',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // — Progress
              _buildProgressSection(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(HomeLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.homeProgress,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${state.totalCompleted} / ${state.totalChallenges}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: LinearProgressIndicator(
            value: state.progressPercent,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: AppDimensions.progressBarHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildFreeCodingCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/editor'),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.code_off_rounded,
              color: AppColors.textPrimary,
              size: AppDimensions.iconL,
            ),
            SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Bebas',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bereksperimen tanpa batasan challenge',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Section
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends StatefulWidget {
  final ChallengeCategory category;
  final Set<String> completedIds;

  const _CategorySection({
    required this.category,
    required this.completedIds,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final completed = widget.category.challenges
        .where((c) => widget.completedIds.contains(c.id))
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // — Category header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: [
                  Text(
                    widget.category.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completed/${widget.category.totalChallenges} selesai',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // — Challenges
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isExpanded
                ? _buildChallengeList(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeList(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.border),
        ...widget.category.challenges.map(
          (challenge) => _ChallengeItem(
            challenge: challenge,
            isCompleted: widget.completedIds.contains(challenge.id),
            isUnlocked: _isUnlocked(challenge),
          ),
        ),
      ],
    );
  }

  bool _isUnlocked(Challenge challenge) {
    final index = widget.category.challenges.indexOf(challenge);
    if (index == 0) return true;
    final prev = widget.category.challenges[index - 1];
    return widget.completedIds.contains(prev.id);
  }
}

class _ChallengeItem extends StatelessWidget {
  final Challenge challenge;
  final bool isCompleted;
  final bool isUnlocked;

  const _ChallengeItem({
    required this.challenge,
    required this.isCompleted,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? () => _openChallenge(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingM,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            // — Status icon
            _buildStatusIcon(),
            const SizedBox(width: AppDimensions.spacingM),

            // — Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: TextStyle(
                      color: isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    challenge.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // — Level badge
            const SizedBox(width: AppDimensions.spacingS),
            _buildLevelBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (isCompleted) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.success,
        child: Icon(
          Icons.check_rounded,
          color: AppColors.textPrimary,
          size: 16,
        ),
      );
    }
    if (!isUnlocked) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(
          Icons.lock_rounded,
          color: AppColors.textDisabled,
          size: 14,
        ),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }

  Widget _buildLevelBadge() {
    final (color, label) = switch (challenge.level) {
      ChallengeLevel.beginner => (AppColors.success, '●'),
      ChallengeLevel.intermediate => (AppColors.warning, '●●'),
      ChallengeLevel.advanced => (AppColors.error, '●●●'),
    };

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 10, letterSpacing: -2),
    );
  }

  void _openChallenge(BuildContext context) {
    context.push('/editor/${challenge.id}');
  }
}

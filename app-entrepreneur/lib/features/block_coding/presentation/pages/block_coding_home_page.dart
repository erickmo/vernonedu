import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vernonedu_entrepreneurship_app/core/constants/app_colors.dart';
import 'package:vernonedu_entrepreneurship_app/core/constants/app_dimensions.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/data/challenge_local_datasource.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/challenge.dart';

const String _kCompletedKey = 'bc_completed_challenges';

/// Halaman beranda fitur Block Coding — daftar kategori dan challenge.
class BlockCodingHomePage extends StatefulWidget {
  const BlockCodingHomePage({super.key});

  @override
  State<BlockCodingHomePage> createState() => _BlockCodingHomePageState();
}

class _BlockCodingHomePageState extends State<BlockCodingHomePage> {
  final _datasource = ChallengeLocalDatasource();
  Set<String> _completedIds = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedIds = (prefs.getStringList(_kCompletedKey) ?? []).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _datasource.getCategories();
    final total =
        categories.fold<int>(0, (s, c) => s + c.challenges.length);
    final completed = _completedIds.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(completed, total),
          const SizedBox(height: AppDimensions.spacingL),
          _buildFreeModeCard(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildSectionTitle('Tantangan'),
          const SizedBox(height: AppDimensions.spacingM),
          ...categories.map(
            (cat) => _CategoryCard(
              category: cat,
              completedIds: _completedIds,
              onChallengeOpened: (id) =>
                  context.push('/block-coding/editor/$id'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int completed, int total) {
    final percent = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C2B), Color(0xFF2D2D44)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: const Icon(
                  Icons.widgets_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Block Coding',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Belajar algoritma dengan visual blocks',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Belajar',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Text(
                '$completed / $total selesai',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6C5CE7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeModeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/block-coding/editor'),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: const Icon(
                Icons.code_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Bebas',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Bereksperimen tanpa tantangan — tulis program apapun',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final ChallengeCategory category;
  final Set<String> completedIds;
  final void Function(String challengeId) onChallengeOpened;

  const _CategoryCard({
    required this.category,
    required this.completedIds,
    required this.onChallengeOpened,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final completed = widget.category.challenges
        .where((c) => widget.completedIds.contains(c.id))
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: [
                  Text(
                    widget.category.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.title,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$completed / ${widget.category.totalChallenges} selesai',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress mini ring
                  _buildMiniProgress(completed, widget.category.totalChallenges),
                  const SizedBox(width: AppDimensions.spacingS),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.5,
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
          // Challenge list
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...widget.category.challenges.asMap().entries.map((entry) {
              final index = entry.key;
              final challenge = entry.value;
              final isCompleted =
                  widget.completedIds.contains(challenge.id);
              final isUnlocked = index == 0 ||
                  widget.completedIds
                      .contains(widget.category.challenges[index - 1].id);
              return _ChallengeRow(
                challenge: challenge,
                isCompleted: isCompleted,
                isUnlocked: isUnlocked,
                onTap: isUnlocked
                    ? () => widget.onChallengeOpened(challenge.id)
                    : null,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniProgress(int done, int total) {
    final pct = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: 3,
            backgroundColor: AppColors.divider,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.success),
          ),
          Text(
            '$done',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final Challenge challenge;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _ChallengeRow({
    required this.challenge,
    required this.isCompleted,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingM,
        ),
        child: Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: GoogleFonts.inter(
                      color: isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    challenge.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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
        radius: 14,
        backgroundColor: AppColors.success,
        child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
      );
    }
    if (!isUnlocked) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.divider,
        child: Icon(Icons.lock_rounded, color: AppColors.textHint, size: 12),
      );
    }
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Color(0xFFEDE7F6),
      child: Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 14),
    );
  }

  Widget _buildLevelBadge() {
    final (color, label) = switch (challenge.level) {
      ChallengeLevel.beginner => (AppColors.success, 'Pemula'),
      ChallengeLevel.intermediate => (AppColors.warning, 'Menengah'),
      ChallengeLevel.advanced => (AppColors.error, 'Lanjut'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

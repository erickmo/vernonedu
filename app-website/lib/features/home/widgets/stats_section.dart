import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/scroll_animate_widget.dart';

/// Stats section — 4 trust metrics dengan gradient lavender card.
class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  static const _stats = [
    _StatData(target: 10000, suffix: '+', label: 'Pelajar Aktif', icon: Icons.people_rounded, description: 'Dari seluruh Indonesia'),
    _StatData(target: 50, suffix: '+', label: 'Kursus Premium', icon: Icons.auto_stories_rounded, description: 'Dikurasi oleh tim ahli'),
    _StatData(target: 95, suffix: '%', label: 'Tingkat Keberhasilan', icon: Icons.trending_up_rounded, description: 'Pelajar capai target'),
    _StatData(target: 200, suffix: '+', label: 'Instruktur Ahli', icon: Icons.workspace_premium_rounded, description: 'Praktisi berpengalaman'),
  ];

  static const _iconColors = [
    AppColors.brandPurple,
    AppColors.brandBlue,
    AppColors.brandGreen,
    AppColors.brandOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);

    return ScrollAnimateWidget(
      uniqueKey: 'stats_section',
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? AppDimensions.s24 : padH,
          vertical: AppDimensions.s48,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppDimensions.s24 : AppDimensions.s48,
          vertical: AppDimensions.s48,
        ),
        decoration: BoxDecoration(
          // Lavender gradient mengikuti design brand
          gradient: const LinearGradient(
            colors: [Color(0xFFD4C9F0), Color(0xFFC4B5EA), Color(0xFFD0C5EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.r24),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: isMobile
            ? _MobileStats(stats: _stats, iconColors: _iconColors)
            : _DesktopStats(stats: _stats, iconColors: _iconColors),
      ),
    );
  }
}

class _DesktopStats extends StatelessWidget {
  final List<_StatData> stats;
  final List<Color> iconColors;

  const _DesktopStats({required this.stats, required this.iconColors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _StatCard(stat: stat, index: i, color: iconColors[i])),
              if (i < stats.length - 1)
                Container(width: 1, height: 80, color: Colors.white.withValues(alpha: 0.4)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MobileStats extends StatelessWidget {
  final List<_StatData> stats;
  final List<Color> iconColors;

  const _MobileStats({required this.stats, required this.iconColors});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppDimensions.s24,
      crossAxisSpacing: AppDimensions.s24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: stats.asMap().entries.map((entry) {
        return _StatCard(
          stat: entry.value,
          index: entry.key,
          color: iconColors[entry.key],
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData stat;
  final int index;
  final Color color;

  const _StatCard({required this.stat, required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(stat.icon, color: color, size: 26),
        )
            .animate(delay: (index * 100).ms)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8)),

        const SizedBox(height: AppDimensions.s16),

        // Counter — teks gelap karena background lavender
        _LavenderCounter(
          target: stat.target,
          suffix: stat.suffix,
          label: stat.label,
          index: index,
        ),

        const SizedBox(height: AppDimensions.s8),

        Text(
          stat.description,
          style: AppTextStyles.bodyXS.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _LavenderCounter extends StatefulWidget {
  final int target;
  final String suffix;
  final String label;
  final int index;

  const _LavenderCounter({
    required this.target,
    required this.suffix,
    required this.label,
    required this.index,
  });

  @override
  State<_LavenderCounter> createState() => _LavenderCounterState();
}

class _LavenderCounterState extends State<_LavenderCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500 + widget.index * 200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _started = true;
          _ctrl.forward();
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final val = (_anim.value * widget.target).round();
            final display = val >= 1000
                ? '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}k'
                : val.toString();
            return Text(
              '$display${widget.suffix}',
              style: AppTextStyles.statNumber.copyWith(
                color: AppColors.bgDarkSection,
                fontSize: 40,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          style: AppTextStyles.statLabel.copyWith(
            color: AppColors.bgDarkSection.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate(delay: (200 + widget.index * 100).ms).fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }
}

class _StatData {
  final int target;
  final String suffix;
  final String label;
  final IconData icon;
  final String description;

  const _StatData({
    required this.target,
    required this.suffix,
    required this.label,
    required this.icon,
    required this.description,
  });
}

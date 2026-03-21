import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Halaman manajemen kebiasaan.
class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  final _mockHabits = [
    (
      emoji: '🦷',
      title: 'Sikat Gigi Pagi',
      streak: 7,
      checked: true,
      color: AppColors.funTeal,
    ),
    (
      emoji: '🛏️',
      title: 'Rapikan Tempat Tidur',
      streak: 3,
      checked: false,
      color: AppColors.funPurple,
    ),
    (
      emoji: '🍎',
      title: 'Makan Buah',
      streak: 12,
      checked: false,
      color: AppColors.accent,
    ),
    (
      emoji: '📖',
      title: 'Belajar 30 Menit',
      streak: 5,
      checked: true,
      color: AppColors.primary,
    ),
    (
      emoji: '🚶',
      title: 'Jalan Kaki Pagi',
      streak: 0,
      checked: false,
      color: AppColors.funOrange,
    ),
  ];

  late final List<bool> _checkedStates;

  @override
  void initState() {
    super.initState();
    _checkedStates = _mockHabits.map((h) => h.checked).toList();
  }

  void _toggleHabit(int index) {
    setState(() => _checkedStates[index] = !_checkedStates[index]);
    if (_checkedStates[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.habitChecked),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get _totalChecked => _checkedStates.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(AppStrings.myHabits, style: AppTextStyles.headingL),
                  const SizedBox(height: AppDimensions.spacingM),

                  // Daily progress
                  _buildDailyProgress(),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Weekly streak chart
                  _buildWeeklyChart(),
                  const SizedBox(height: AppDimensions.spacingL),

                  Text(AppStrings.dailyHabits, style: AppTextStyles.headingM),
                  const SizedBox(height: AppDimensions.spacingS),
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              sliver: SliverList.separated(
                itemCount: _mockHabits.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.spacingS),
                itemBuilder: (context, i) => _HabitCard(
                  emoji: _mockHabits[i].emoji,
                  title: _mockHabits[i].title,
                  streak: _mockHabits[i].streak,
                  isChecked: _checkedStates[i],
                  color: _mockHabits[i].color,
                  onTap: () => _toggleHabit(i),
                ),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppDimensions.spacingXXL),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppStrings.addHabit,
          style: AppTextStyles.buttonM.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDailyProgress() {
    final progress = _totalChecked / _mockHabits.length;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progress Hari Ini',
                style: AppTextStyles.labelL.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '$_totalChecked / ${_mockHabits.length}',
                style: AppTextStyles.headingM.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            progress == 1.0
                ? '🎉 Sempurna! Semua kebiasaan selesai!'
                : 'Yuk selesaikan ${_mockHabits.length - _totalChecked} kebiasaan lagi!',
            style: AppTextStyles.bodyS.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final values = [0.9, 1.0, 0.7, 1.0, 0.8, 0.6, 0.4];
    final today = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Streak Minggu Ini', style: AppTextStyles.headingS),
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final isToday = i == today;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 32,
                  height: 48 * values[i],
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  days[i],
                  style: AppTextStyles.labelS.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textHint,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.spacingM,
          AppDimensions.spacingM,
          AppDimensions.spacingM,
          MediaQuery.of(context).viewInsets.bottom + AppDimensions.spacingXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(AppStrings.addHabit, style: AppTextStyles.headingM),
            const SizedBox(height: AppDimensions.spacingM),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nama Kebiasaan'),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.save, style: AppTextStyles.buttonL),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final String emoji;
  final String title;
  final int streak;
  final bool isChecked;
  final Color color;
  final VoidCallback onTap;

  const _HabitCard({
    required this.emoji,
    required this.title,
    required this.streak,
    required this.isChecked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: isChecked ? color.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: isChecked ? color : AppColors.divider,
            width: isChecked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelL),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Row(
                    children: [
                      Text(
                        '🔥 $streak hari berturut-turut',
                        style: AppTextStyles.bodyS.copyWith(
                          color: streak > 0
                              ? AppColors.streakFire
                              : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isChecked ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isChecked ? color : AppColors.divider,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check_rounded,
                      size: 20, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

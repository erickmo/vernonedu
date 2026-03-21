import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../domain/entities/class_doc_post_entity.dart';
import '../../../domain/entities/pr_schedule_entity.dart';
import '../../../domain/entities/social_media_post_entity.dart';
import '../../cubit/marketing_cubit.dart';
import '../../cubit/marketing_state.dart';

class MarketingCalendarTab extends StatefulWidget {
  const MarketingCalendarTab({super.key});

  @override
  State<MarketingCalendarTab> createState() => _MarketingCalendarTabState();
}

class _MarketingCalendarTabState extends State<MarketingCalendarTab> {
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  static const _weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        final posts = state is MarketingLoaded
            ? state.posts
            : <SocialMediaPostEntity>[];
        final pr = state is MarketingLoaded
            ? state.prSchedules
            : <PrScheduleEntity>[];
        final docs = state is MarketingLoaded
            ? state.classDocs
            : <ClassDocPostEntity>[];

        // Build event map: day -> list of colors
        final Map<int, List<Color>> events = {};

        for (final post in posts) {
          if (post.scheduledAt.year == _currentMonth.year &&
              post.scheduledAt.month == _currentMonth.month) {
            final day = post.scheduledAt.day;
            events[day] ??= [];
            events[day]!.add(
                post.status == 'posted' ? AppColors.success : AppColors.info);
          }
        }
        for (final p in pr) {
          if (p.scheduledAt.year == _currentMonth.year &&
              p.scheduledAt.month == _currentMonth.month) {
            final day = p.scheduledAt.day;
            events[day] ??= [];
            events[day]!.add(AppColors.warning);
          }
        }
        for (final doc in docs) {
          if (doc.scheduledPostDate.year == _currentMonth.year &&
              doc.scheduledPostDate.month == _currentMonth.month) {
            final day = doc.scheduledPostDate.day;
            events[day] ??= [];
            events[day]!.add(Colors.purple);
          }
        }

        final firstDay =
            DateTime(_currentMonth.year, _currentMonth.month, 1);
        final daysInMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
        final startWeekday = firstDay.weekday % 7; // 0=Sun

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend
              _buildLegend(),
              const SizedBox(height: AppDimensions.md),
              // Calendar container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Column(
                  children: [
                    // Month nav
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _prevMonth,
                        ),
                        Text(
                          _monthLabel(_currentMonth),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    // Weekday headers
                    Row(
                      children: _weekdays
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(d,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppDimensions.xs),
                    // Days grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: startWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < startWeekday) {
                          return const SizedBox.shrink();
                        }
                        final day = index - startWeekday + 1;
                        final dayEvents = events[day] ?? [];
                        final isToday =
                            DateTime.now().year == _currentMonth.year &&
                                DateTime.now().month == _currentMonth.month &&
                                DateTime.now().day == day;

                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primarySurface
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            border: isToday
                                ? Border.all(
                                    color: AppColors.primary, width: 1.5)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (dayEvents.isNotEmpty)
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 2,
                                  children: dayEvents
                                      .take(3)
                                      .map((c) => Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: c,
                                              shape: BoxShape.circle,
                                            ),
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.sm,
      children: const [
        _LegendItem(color: AppColors.info, label: 'Social Media (Dijadwalkan)'),
        _LegendItem(color: AppColors.success, label: 'Social Media (Diposting)'),
        _LegendItem(color: AppColors.warning, label: 'PR / Event'),
        _LegendItem(color: Colors.purple, label: 'Dokumentasi Kelas'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

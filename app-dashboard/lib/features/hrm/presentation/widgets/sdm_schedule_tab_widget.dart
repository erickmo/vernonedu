import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Tab jadwal / kalender SDM.
class SdmScheduleTabWidget extends StatefulWidget {
  final List<SdmScheduleEntity> schedules;

  const SdmScheduleTabWidget({super.key, required this.schedules});

  @override
  State<SdmScheduleTabWidget> createState() => _SdmScheduleTabWidgetState();
}

class _SdmScheduleTabWidgetState extends State<SdmScheduleTabWidget> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) {
      return _buildEmpty(context);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildCalendarPanel(context),
        ),
        Container(width: 1, color: AppColors.border),
        Expanded(
          flex: 3,
          child: _buildScheduleList(context),
        ),
      ],
    );
  }

  Widget _buildCalendarPanel(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthNavigator(context),
          const SizedBox(height: AppDimensions.md),
          _buildCalendarGrid(context),
          const SizedBox(height: AppDimensions.lg),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: _prevMonth,
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
            color: AppColors.textSecondary,
          ),
          Expanded(
            child: Text(
              '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
            color: AppColors.textSecondary,
          ),
        ],
      );

  Widget _buildCalendarGrid(BuildContext context) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startWeekday = firstDay.weekday; // 1=Mon, 7=Sun
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    final scheduleDates = widget.schedules
        .where((s) =>
            s.date.year == _selectedMonth.year &&
            s.date.month == _selectedMonth.month)
        .map((s) => s.date.day)
        .toSet();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimensions.sm),
      child: Column(
        children: [
          Row(
            children: days
                .map((d) => Expanded(
                      child: Text(
                        d,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppDimensions.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: (startWeekday - 1) + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startWeekday - 1) return const SizedBox.shrink();
              final day = index - (startWeekday - 1) + 1;
              final hasEvent = scheduleDates.contains(day);
              final isToday = DateTime.now().year == _selectedMonth.year &&
                  DateTime.now().month == _selectedMonth.month &&
                  DateTime.now().day == day;
              return _buildCalendarDay(context, day, hasEvent, isToday);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    BuildContext context,
    int day,
    bool hasEvent,
    bool isToday,
  ) =>
      Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary
              : hasEvent
                  ? AppColors.primarySurface
                  : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                    fontWeight:
                        hasEvent || isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
            if (hasEvent && !isToday)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildLegend(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.sdmScheduleLegend,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...SdmScheduleType.values.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.xs),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _typeColor(t),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    _typeLabel(t),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildScheduleList(BuildContext context) {
    final sorted = [...widget.schedules]
      ..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = sorted
        .where((s) =>
            s.status == SdmScheduleStatus.upcoming ||
            s.status == SdmScheduleStatus.ongoing)
        .toList();
    final past = sorted
        .where((s) => s.status == SdmScheduleStatus.completed)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcoming.isNotEmpty) ...[
            _buildSectionLabel(context, AppStrings.sdmScheduleUpcoming),
            const SizedBox(height: AppDimensions.sm),
            ...upcoming.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                  child: _buildScheduleCard(context, s),
                )),
          ],
          if (past.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            _buildSectionLabel(context, AppStrings.sdmSchedulePast),
            const SizedBox(height: AppDimensions.sm),
            ...past.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                  child: _buildScheduleCard(context, s),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) => Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
      );

  Widget _buildScheduleCard(BuildContext context, SdmScheduleEntity sched) =>
      Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border(
            left: BorderSide(color: _typeColor(sched.type), width: 4),
            top: const BorderSide(color: AppColors.border),
            right: const BorderSide(color: AppColors.border),
            bottom: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sched.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (sched.programName != null)
                    Text(
                      sched.programName!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  const SizedBox(height: AppDimensions.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: AppDimensions.iconSm,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        '${sched.startTime} — ${sched.endTime}',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                      ),
                      if (sched.location != null) ...[
                        const SizedBox(width: AppDimensions.sm),
                        Icon(
                          Icons.location_on_outlined,
                          size: AppDimensions.iconSm,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        Text(
                          sched.location!,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.textHint,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${sched.date.day} ${_shortMonth(sched.date.month)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppDimensions.xs),
                _buildStatusChip(context, sched.status),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatusChip(BuildContext context, SdmScheduleStatus status) {
    final color = _scheduleStatusColor(status);
    final bgColor = color.withOpacity(0.1);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        _scheduleStatusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                AppStrings.sdmNoScheduleData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );

  void _prevMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });

  Color _typeColor(SdmScheduleType t) {
    switch (t) {
      case SdmScheduleType.clasSession:
        return AppColors.primary;
      case SdmScheduleType.meeting:
        return AppColors.info;
      case SdmScheduleType.review:
        return AppColors.warning;
      case SdmScheduleType.training:
        return AppColors.secondary;
      case SdmScheduleType.other:
        return AppColors.textSecondary;
    }
  }

  String _typeLabel(SdmScheduleType t) {
    switch (t) {
      case SdmScheduleType.clasSession:
        return 'Sesi Kelas';
      case SdmScheduleType.meeting:
        return 'Meeting';
      case SdmScheduleType.review:
        return 'Review';
      case SdmScheduleType.training:
        return 'Pelatihan';
      case SdmScheduleType.other:
        return 'Lainnya';
    }
  }

  Color _scheduleStatusColor(SdmScheduleStatus s) {
    switch (s) {
      case SdmScheduleStatus.upcoming:
        return AppColors.info;
      case SdmScheduleStatus.ongoing:
        return AppColors.success;
      case SdmScheduleStatus.completed:
        return AppColors.textHint;
      case SdmScheduleStatus.cancelled:
        return AppColors.error;
    }
  }

  String _scheduleStatusLabel(SdmScheduleStatus s) {
    switch (s) {
      case SdmScheduleStatus.upcoming:
        return 'Akan Datang';
      case SdmScheduleStatus.ongoing:
        return 'Berlangsung';
      case SdmScheduleStatus.completed:
        return 'Selesai';
      case SdmScheduleStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String _monthName(int m) => const [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ][m];

  String _shortMonth(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ][m];
}

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
import '../../domain/entities/schedule_session_entity.dart';
import '../cubit/schedule_cubit.dart';
import '../cubit/schedule_state.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<ScheduleCubit>();
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        cubit.loadWeek(weekStart);
        return cubit;
      },
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatelessWidget {
  const _ScheduleView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.schedule),
        backgroundColor: AppColors.surface,
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildWeekNav(context, state),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeekNav(BuildContext context, ScheduleState state) {
    DateTime? weekStart;
    if (state is ScheduleLoaded) weekStart = state.weekStart;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding,
        vertical: AppDimensions.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => context.read<ScheduleCubit>().previousWeek(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
          ),
          Expanded(
            child: Text(
              weekStart != null
                  ? _weekLabel(weekStart)
                  : AppStrings.schedule,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => context.read<ScheduleCubit>().nextWeek(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startStr = DateUtil.toDisplay(weekStart);
    final endStr = DateUtil.toDisplay(weekEnd);
    return '$startStr – $endStr';
  }

  Widget _buildBody(BuildContext context, ScheduleState state) {
    if (state is ScheduleLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ScheduleError) {
      return ErrorView(
        message: state.message,
        onRetry: () {
          final now = DateTime.now();
          final weekStart = DateTime(
            now.year,
            now.month,
            now.day - (now.weekday - 1),
          );
          context.read<ScheduleCubit>().loadWeek(weekStart);
        },
      );
    }
    if (state is ScheduleLoaded) {
      if (state.sessions.isEmpty) {
        return const EmptyView(
          icon: Icons.calendar_today_outlined,
          message: AppStrings.noSchedule,
        );
      }
      return _buildSessionList(context, state);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildSessionList(BuildContext context, ScheduleLoaded state) {
    final grouped = state.grouped;
    final days = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final sessions = grouped[day]!;
        return _DayGroup(day: day, sessions: sessions);
      },
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime day;
  final List<ScheduleSessionEntity> sessions;

  const _DayGroup({required this.day, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDayHeader(context),
        const SizedBox(height: AppDimensions.sm),
        ...sessions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: _ScheduleCard(session: s),
            )),
        const SizedBox(height: AppDimensions.md),
      ],
    );
  }

  Widget _buildDayHeader(BuildContext context) {
    final isToday = _isToday(day);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary
                : AppColors.surfaceVariant,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          child: Text(
            DateUtil.toDisplayWithDay(day),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isToday ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleSessionEntity session;

  const _ScheduleCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: session.isToday || session.isPast
          ? () => context.push('/batches/${session.batchId}/attendance')
          : null,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: session.isToday
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            width: session.isToday ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildTimeIndicator(),
            const SizedBox(width: AppDimensions.md),
            Expanded(child: _buildInfo(context)),
            if (session.isToday || session.isPast)
              const Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeIndicator() => Column(
        children: [
          Text(
            _formatTime(session.scheduledAt),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 2,
            height: 24,
            color: session.hasStarted
                ? AppColors.success
                : AppColors.primarySurface,
          ),
        ],
      );

  Widget _buildInfo(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.displayTitle,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${session.masterCourseName} · ${session.batchCode}',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (session.location != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(
                  session.location!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ],
          if (session.hasStarted)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Absensi sudah dimulai',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.success),
              ),
            ),
        ],
      );

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

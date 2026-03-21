import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../batch/domain/entities/batch_detail_entity.dart';
import '../../../batch/domain/entities/enrolled_student_entity.dart';
import '../../../batch/presentation/cubit/batch_detail_cubit.dart';
import '../../../batch/presentation/cubit/batch_detail_state.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';

class AttendancePage extends StatelessWidget {
  final String batchId;

  const AttendancePage({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<AttendanceCubit>()..loadSessions(batchId),
        ),
        BlocProvider(
          create: (_) =>
              getIt<BatchDetailCubit>()..loadDetail(batchId),
        ),
      ],
      child: _AttendanceView(batchId: batchId),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  final String batchId;

  const _AttendanceView({required this.batchId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.attendanceSaved),
              backgroundColor: AppColors.success,
            ),
          );
          context.read<AttendanceCubit>().loadSessions(batchId);
        }
      },
      builder: (context, state) {
        if (state is AttendanceTaking) {
          return _TakingAttendanceView(
            state: state,
            batchId: batchId,
          );
        }
        return _SessionListView(batchId: batchId, state: state);
      },
    );
  }
}

// ─── Session List ─────────────────────────────────────────────────────────────

class _SessionListView extends StatelessWidget {
  final String batchId;
  final AttendanceState state;

  const _SessionListView({required this.batchId, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.attendance),
        backgroundColor: AppColors.surface,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (state is AttendanceLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AttendanceError) {
      return ErrorView(
        message: (state as AttendanceError).message,
        onRetry: () => context.read<AttendanceCubit>().loadSessions(batchId),
      );
    }
    if (state is AttendanceSessionsLoaded) {
      final sessions = (state as AttendanceSessionsLoaded).sessions;
      if (sessions.isEmpty) {
        return const EmptyView(
          icon: Icons.event_note_outlined,
          message: 'Belum ada sesi terjadwal',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        itemCount: sessions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.sm),
        itemBuilder: (context, i) => _SessionCard(
          session: sessions[i],
          onTap: () => _startAttendance(context, sessions[i]),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  void _startAttendance(
      BuildContext context, AttendanceSessionEntity session) {
    final batchDetailState = context.read<BatchDetailCubit>().state;
    List<EnrolledStudentEntity> students = [];
    if (batchDetailState is BatchDetailLoaded) {
      students = batchDetailState.detail.students;
    }
    context
        .read<AttendanceCubit>()
        .startAttendance(session, students);
  }
}

class _SessionCard extends StatelessWidget {
  final AttendanceSessionEntity session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtil.isToday(session.scheduledAt);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildSessionNumber(),
            const SizedBox(width: AppDimensions.md),
            Expanded(child: _buildInfo(context)),
            _buildAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionNumber() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: session.hasStarted
              ? AppColors.successSurface
              : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Center(
          child: Text(
            '${session.sessionNumber}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: session.hasStarted ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      );

  Widget _buildInfo(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.topic ?? 'Sesi ${session.sessionNumber}',
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            DateUtil.relativeDay(session.scheduledAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DateUtil.isToday(session.scheduledAt)
                      ? AppColors.primary
                      : null,
                  fontWeight: DateUtil.isToday(session.scheduledAt)
                      ? FontWeight.w500
                      : null,
                ),
          ),
          if (session.hasStarted)
            Text(
              session.attendanceSummary,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.success),
            ),
        ],
      );

  Widget _buildAction() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: const Text(
          'Absen',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
      );
}

// ─── Taking Attendance View ────────────────────────────────────────────────────

class _TakingAttendanceView extends StatelessWidget {
  final AttendanceTaking state;
  final String batchId;

  const _TakingAttendanceView({required this.state, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Sesi ${state.session.sessionNumber} — Absensi',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              context.read<AttendanceCubit>().loadSessions(batchId),
        ),
        actions: [
          TextButton(
            onPressed: state.isSubmitting
                ? null
                : () => _confirmSubmit(context),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(context),
          Expanded(
            child: state.records.isEmpty
                ? const EmptyView(
                    icon: Icons.people_outline,
                    message: 'Tidak ada siswa',
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.all(AppDimensions.pagePadding),
                    itemCount: state.records.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.xs),
                    itemBuilder: (_, i) =>
                        _AttendanceTile(record: state.records[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: [
            _SummaryChip(
              label: AppStrings.markPresent,
              count: state.presentCount,
              color: AppColors.success,
            ),
            const SizedBox(width: AppDimensions.sm),
            _SummaryChip(
              label: AppStrings.markLate,
              count: state.lateCount,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppDimensions.sm),
            _SummaryChip(
              label: AppStrings.markAbsent,
              count: state.absentCount,
              color: AppColors.error,
            ),
            const SizedBox(width: AppDimensions.sm),
            _SummaryChip(
              label: AppStrings.markExcused,
              count: state.excusedCount,
              color: AppColors.info,
            ),
          ],
        ),
      );

  void _confirmSubmit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.attendanceConfirmTitle),
        content: const Text(AppStrings.attendanceConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AttendanceCubit>().submitAttendance(batchId);
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final AttendanceRecordEntity record;

  const _AttendanceTile({required this.record});

  static const _statuses = [
    AppConstants.attendancePresent,
    AppConstants.attendanceLate,
    AppConstants.attendanceAbsent,
    AppConstants.attendanceExcused,
  ];

  static const _statusLabels = {
    AppConstants.attendancePresent: 'H',
    AppConstants.attendanceLate: 'T',
    AppConstants.attendanceAbsent: 'A',
    AppConstants.attendanceExcused: 'I',
  };

  static const _statusColors = {
    AppConstants.attendancePresent: AppColors.success,
    AppConstants.attendanceLate: AppColors.warning,
    AppConstants.attendanceAbsent: AppColors.error,
    AppConstants.attendanceExcused: AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
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
              record.initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.studentName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontSize: 13)),
                Text(record.studentCode,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _buildStatusButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(BuildContext context) => Row(
        children: _statuses.map((s) {
          final isSelected = record.status == s;
          final color = _statusColors[s]!;
          return GestureDetector(
            onTap: () =>
                context.read<AttendanceCubit>().updateRecord(
                      record.studentId,
                      s,
                    ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(left: AppDimensions.xs),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _statusLabels[s]!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

import 'package:equatable/equatable.dart';

import '../../domain/entities/schedule_session_entity.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  final List<ScheduleSessionEntity> sessions;
  final DateTime weekStart;

  const ScheduleLoaded({required this.sessions, required this.weekStart});

  /// Sessions grouped by date (year-month-day).
  Map<DateTime, List<ScheduleSessionEntity>> get grouped {
    final map = <DateTime, List<ScheduleSessionEntity>>{};
    for (final s in sessions) {
      final day = DateTime(
          s.scheduledAt.year, s.scheduledAt.month, s.scheduledAt.day);
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }

  @override
  List<Object?> get props => [sessions, weekStart];
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}

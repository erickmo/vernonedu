import 'package:equatable/equatable.dart';

import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceSessionsLoaded extends AttendanceState {
  final List<AttendanceSessionEntity> sessions;

  const AttendanceSessionsLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class AttendanceTaking extends AttendanceState {
  final AttendanceSessionEntity session;
  final List<AttendanceRecordEntity> records;
  final bool isSubmitting;

  const AttendanceTaking({
    required this.session,
    required this.records,
    this.isSubmitting = false,
  });

  AttendanceTaking copyWith({
    List<AttendanceRecordEntity>? records,
    bool? isSubmitting,
  }) =>
      AttendanceTaking(
        session: session,
        records: records ?? this.records,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );

  int get presentCount =>
      records.where((r) => r.status == 'present').length;
  int get lateCount => records.where((r) => r.status == 'late').length;
  int get absentCount =>
      records.where((r) => r.status == 'absent').length;
  int get excusedCount =>
      records.where((r) => r.status == 'excused').length;

  @override
  List<Object?> get props => [session, records, isSubmitting];
}

class AttendanceSubmitted extends AttendanceState {
  const AttendanceSubmitted();
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}

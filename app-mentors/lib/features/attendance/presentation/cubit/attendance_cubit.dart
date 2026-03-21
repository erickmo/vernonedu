import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/usecases/get_attendance_sessions_usecase.dart';
import '../../domain/usecases/submit_attendance_usecase.dart';
import '../../../batch/domain/entities/enrolled_student_entity.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final GetAttendanceSessionsUseCase _getSessionsUseCase;
  final SubmitAttendanceUseCase _submitUseCase;

  AttendanceCubit({
    required GetAttendanceSessionsUseCase getSessionsUseCase,
    required SubmitAttendanceUseCase submitUseCase,
  })  : _getSessionsUseCase = getSessionsUseCase,
        _submitUseCase = submitUseCase,
        super(const AttendanceInitial());

  Future<void> loadSessions(String batchId) async {
    emit(const AttendanceLoading());
    final result = await _getSessionsUseCase(batchId);
    result.fold(
      (failure) => emit(AttendanceError(failure.message)),
      (sessions) => emit(AttendanceSessionsLoaded(sessions)),
    );
  }

  /// Start taking attendance for a session, pre-populating with students.
  void startAttendance(
    AttendanceSessionEntity session,
    List<EnrolledStudentEntity> students,
  ) {
    final records = students
        .map((s) => AttendanceRecordEntity(
              studentId: s.studentId,
              studentName: s.studentName,
              studentCode: s.studentCode,
              status: AppConstants.attendancePresent,
            ))
        .toList();
    emit(AttendanceTaking(session: session, records: records));
  }

  void updateRecord(String studentId, String status) {
    final current = state;
    if (current is! AttendanceTaking) return;
    final updated = current.records.map((r) {
      if (r.studentId == studentId) return r.copyWith(status: status);
      return r;
    }).toList();
    emit(current.copyWith(records: updated));
  }

  Future<bool> submitAttendance(String batchId) async {
    final current = state;
    if (current is! AttendanceTaking) return false;

    emit(current.copyWith(isSubmitting: true));
    final result = await _submitUseCase(
      batchId,
      current.session.id,
      current.records,
    );
    return result.fold(
      (failure) {
        emit(current.copyWith(isSubmitting: false));
        return false;
      },
      (_) {
        emit(const AttendanceSubmitted());
        return true;
      },
    );
  }
}

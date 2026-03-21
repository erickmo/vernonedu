import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/student_enrollment_history_entity.dart';
import '../../domain/entities/student_note_entity.dart';
import '../../domain/entities/recommended_course_entity.dart';
import '../../domain/entities/student_crm_log_entity.dart';
import '../../domain/usecases/get_student_detail_usecase.dart';
import '../../domain/usecases/get_student_enrollment_history_usecase.dart';
import '../../domain/usecases/get_student_recommendations_usecase.dart';
import '../../domain/usecases/get_student_notes_usecase.dart';
import '../../domain/usecases/add_student_note_usecase.dart';
import '../../domain/usecases/update_student_usecase.dart';
import '../../domain/usecases/get_student_crm_logs_usecase.dart';
import '../../domain/usecases/add_student_crm_log_usecase.dart';
import '../../../talentpool/domain/entities/talentpool_entity.dart';
import '../../../talentpool/domain/usecases/get_talentpool_usecase.dart';
import 'student_dashboard_state.dart';

class StudentDashboardCubit extends Cubit<StudentDashboardState> {
  final GetStudentDetailUseCase _getStudentDetail;
  final GetStudentEnrollmentHistoryUseCase _getEnrollmentHistory;
  final GetStudentRecommendationsUseCase _getRecommendations;
  final GetStudentNotesUseCase _getNotes;
  final AddStudentNoteUseCase _addNote;
  final UpdateStudentUseCase _updateStudent;
  final GetTalentPoolUseCase _getTalentPool;
  final GetStudentCrmLogsUseCase _getCrmLogs;
  final AddStudentCrmLogUseCase _addCrmLog;

  StudentDashboardCubit({
    required GetStudentDetailUseCase getStudentDetail,
    required GetStudentEnrollmentHistoryUseCase getEnrollmentHistory,
    required GetStudentRecommendationsUseCase getRecommendations,
    required GetStudentNotesUseCase getNotes,
    required AddStudentNoteUseCase addNote,
    required UpdateStudentUseCase updateStudent,
    required GetTalentPoolUseCase getTalentPool,
    required GetStudentCrmLogsUseCase getCrmLogs,
    required AddStudentCrmLogUseCase addCrmLog,
  })  : _getStudentDetail = getStudentDetail,
        _getEnrollmentHistory = getEnrollmentHistory,
        _getRecommendations = getRecommendations,
        _getNotes = getNotes,
        _addNote = addNote,
        _updateStudent = updateStudent,
        _getTalentPool = getTalentPool,
        _getCrmLogs = getCrmLogs,
        _addCrmLog = addCrmLog,
        super(const StudentDashboardInitial());

  Future<void> loadDashboard(String studentId) async {
    emit(const StudentDashboardLoading());

    final detailResult = await _getStudentDetail(studentId);

    detailResult.fold(
      (failure) => emit(StudentDashboardError(failure.message)),
      (student) async {
        final results = await Future.wait([
          _getEnrollmentHistory(studentId),
          _getRecommendations(studentId),
          _getNotes(studentId),
          _getTalentPool(participantId: studentId, limit: 1),
          _getCrmLogs(studentId),
        ]);

        final enrollments =
            results[0].fold<List<StudentEnrollmentHistoryEntity>>(
          (_) => [],
          (data) => data as List<StudentEnrollmentHistoryEntity>,
        );
        final recommendations = results[1].fold<List<RecommendedCourseEntity>>(
          (_) => [],
          (data) => data as List<RecommendedCourseEntity>,
        );
        final notes = results[2].fold<List<StudentNoteEntity>>(
          (_) => [],
          (data) => data as List<StudentNoteEntity>,
        );
        final talentPoolList = results[3].fold<List<TalentPoolEntity>>(
          (_) => [],
          (data) => data as List<TalentPoolEntity>,
        );
        final crmLogs = results[4].fold<List<StudentCrmLogEntity>>(
          (_) => [],
          (data) => data as List<StudentCrmLogEntity>,
        );

        emit(StudentDashboardLoaded(
          student: student,
          enrollmentHistory: enrollments,
          recommendations: recommendations,
          talentPool: talentPoolList.isNotEmpty ? talentPoolList.first : null,
          notes: notes,
          crmLogs: crmLogs,
        ));
      },
    );
  }

  Future<bool> addNote(String studentId, String content) async {
    final current = state;
    if (current is! StudentDashboardLoaded) return false;

    emit(current.copyWith(isAddingNote: true));

    final result = await _addNote(studentId, content);

    return result.fold(
      (failure) {
        emit(current.copyWith(isAddingNote: false));
        return false;
      },
      (note) {
        emit(current.copyWith(
          notes: [note, ...current.notes],
          isAddingNote: false,
        ));
        return true;
      },
    );
  }

  Future<bool> updateStudent(
    String studentId, {
    required String name,
    required String email,
    required String phone,
    String? nik,
    String? gender,
    String? address,
    String? birthDate,
    String? departmentId,
    String status = 'aktif',
    String? studentCode,
  }) async {
    final current = state;
    if (current is! StudentDashboardLoaded) return false;

    emit(current.copyWith(isUpdating: true));

    bool success = false;
    final result = await _updateStudent(
      studentId,
      name: name,
      email: email,
      phone: phone,
      nik: nik,
      gender: gender,
      address: address,
      birthDate: birthDate,
      departmentId: departmentId,
      status: status,
      studentCode: studentCode,
    );
    result.fold(
      (_) => emit(current.copyWith(isUpdating: false)),
      (_) {
        success = true;
      },
    );

    if (!success) return false;

    final detailResult = await _getStudentDetail(studentId);
    detailResult.fold(
      (_) => emit(current.copyWith(isUpdating: false)),
      (student) => emit(current.copyWith(student: student, isUpdating: false)),
    );
    return true;
  }

  Future<void> refreshNotes(String studentId) async {
    final current = state;
    if (current is! StudentDashboardLoaded) return;

    final result = await _getNotes(studentId);
    result.fold(
      (_) {},
      (notes) => emit(current.copyWith(notes: notes)),
    );
  }

  Future<bool> addCrmLog(
    String studentId, {
    required String contactMethod,
    required String response,
    String? contactedBy,
  }) async {
    final current = state;
    if (current is! StudentDashboardLoaded) return false;

    emit(current.copyWith(isAddingCrmLog: true));

    final result = await _addCrmLog(
      studentId,
      contactMethod: contactMethod,
      response: response,
      contactedBy: contactedBy,
    );

    return result.fold(
      (failure) {
        emit(current.copyWith(isAddingCrmLog: false));
        return false;
      },
      (log) {
        emit(current.copyWith(
          crmLogs: [log, ...current.crmLogs],
          isAddingCrmLog: false,
        ));
        return true;
      },
    );
  }
}

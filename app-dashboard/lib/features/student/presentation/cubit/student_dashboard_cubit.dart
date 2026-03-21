import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/student_enrollment_history_entity.dart';
import '../../domain/entities/student_note_entity.dart';
import '../../domain/entities/recommended_course_entity.dart';
import '../../domain/usecases/get_student_detail_usecase.dart';
import '../../domain/usecases/get_student_enrollment_history_usecase.dart';
import '../../domain/usecases/get_student_recommendations_usecase.dart';
import '../../domain/usecases/get_student_notes_usecase.dart';
import '../../domain/usecases/add_student_note_usecase.dart';
import '../../domain/usecases/update_student_usecase.dart';
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

  StudentDashboardCubit({
    required GetStudentDetailUseCase getStudentDetail,
    required GetStudentEnrollmentHistoryUseCase getEnrollmentHistory,
    required GetStudentRecommendationsUseCase getRecommendations,
    required GetStudentNotesUseCase getNotes,
    required AddStudentNoteUseCase addNote,
    required UpdateStudentUseCase updateStudent,
    required GetTalentPoolUseCase getTalentPool,
  })  : _getStudentDetail = getStudentDetail,
        _getEnrollmentHistory = getEnrollmentHistory,
        _getRecommendations = getRecommendations,
        _getNotes = getNotes,
        _addNote = addNote,
        _updateStudent = updateStudent,
        _getTalentPool = getTalentPool,
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
        ]);

        final enrollments = results[0].fold<List<StudentEnrollmentHistoryEntity>>(
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

        emit(StudentDashboardLoaded(
          student: student,
          enrollmentHistory: enrollments,
          recommendations: recommendations,
          talentPool: talentPoolList.isNotEmpty ? talentPoolList.first : null,
          notes: notes,
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
  }) async {
    final current = state;
    if (current is! StudentDashboardLoaded) return false;

    emit(current.copyWith(isUpdating: true));

    bool success = false;
    final result = await _updateStudent(studentId, name: name, email: email, phone: phone);
    result.fold(
      (_) => emit(current.copyWith(isUpdating: false)),
      (_) { success = true; },
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
}

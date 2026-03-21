import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/student_detail_entity.dart';
import '../entities/student_enrollment_history_entity.dart';
import '../entities/student_note_entity.dart';
import '../entities/recommended_course_entity.dart';

abstract class StudentDetailRepository {
  Future<Either<Failure, StudentDetailEntity>> getStudentDetail(String id);

  Future<Either<Failure, List<StudentEnrollmentHistoryEntity>>>
      getStudentEnrollmentHistory(String studentId);

  Future<Either<Failure, List<RecommendedCourseEntity>>>
      getStudentRecommendations(String studentId);

  Future<Either<Failure, List<StudentNoteEntity>>> getStudentNotes(
      String studentId);

  Future<Either<Failure, StudentNoteEntity>> addStudentNote(
      String studentId, String content);

  Future<Either<Failure, void>> updateStudent(
    String id, {
    required String name,
    required String email,
    required String phone,
  });
}

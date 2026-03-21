import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/student_enrollment_history_entity.dart';
import '../repositories/student_detail_repository.dart';

class GetStudentEnrollmentHistoryUseCase {
  final StudentDetailRepository _repository;

  const GetStudentEnrollmentHistoryUseCase(this._repository);

  Future<Either<Failure, List<StudentEnrollmentHistoryEntity>>> call(
      String studentId) {
    return _repository.getStudentEnrollmentHistory(studentId);
  }
}

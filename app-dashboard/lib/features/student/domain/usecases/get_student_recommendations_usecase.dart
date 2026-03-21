import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/recommended_course_entity.dart';
import '../repositories/student_detail_repository.dart';

class GetStudentRecommendationsUseCase {
  final StudentDetailRepository _repository;

  const GetStudentRecommendationsUseCase(this._repository);

  Future<Either<Failure, List<RecommendedCourseEntity>>> call(
      String studentId) {
    return _repository.getStudentRecommendations(studentId);
  }
}

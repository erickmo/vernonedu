import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_entity.dart';
import '../repositories/course_repository.dart';

// Use case untuk mengambil daftar MasterCourse dengan filter opsional
class GetCoursesUseCase {
  final CourseRepository _repository;
  const GetCoursesUseCase(this._repository);

  Future<Either<Failure, List<CourseEntity>>> call({
    int offset = 0,
    int limit = 20,
    String status = '',
    String field = '',
  }) =>
      _repository.getCourses(
        offset: offset,
        limit: limit,
        status: status,
        field: field,
      );
}

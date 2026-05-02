import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_version_entity.dart';
import '../repositories/course_version_repository.dart';

// Use case to fetch all course versions awaiting approval.
// Backend: GET /api/v1/curriculum/versions/pending  (dept_leader only)
class GetPendingCourseVersionsUseCase {
  final CourseVersionRepository _repository;
  const GetPendingCourseVersionsUseCase(this._repository);

  Future<Either<Failure, List<CourseVersionEntity>>> call() =>
      _repository.getPendingVersions();
}

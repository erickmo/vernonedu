import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_version_repository.dart';

// Use case to approve a submitted course version (dept_leader only).
// Backend: POST /api/v1/curriculum/versions/{versionId}/approve  (no body)
class ApproveCourseVersionUseCase {
  final CourseVersionRepository _repository;
  const ApproveCourseVersionUseCase(this._repository);

  Future<Either<Failure, void>> call(String versionId) =>
      _repository.approveCourseVersion(versionId);
}

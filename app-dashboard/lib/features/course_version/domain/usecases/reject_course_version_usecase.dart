import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_version_repository.dart';

// Use case to reject a submitted course version (dept_leader only).
// Backend: POST /api/v1/curriculum/versions/{versionId}/reject  body: {"reason": string}
class RejectCourseVersionUseCase {
  final CourseVersionRepository _repository;
  const RejectCourseVersionUseCase(this._repository);

  Future<Either<Failure, void>> call(String versionId, String reason) =>
      _repository.rejectCourseVersion(versionId, reason);
}

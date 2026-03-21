import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_version_repository.dart';

// Use case untuk mempromosikan status versi: draft → review → approved
class PromoteCourseVersionUseCase {
  final CourseVersionRepository _repository;
  const PromoteCourseVersionUseCase(this._repository);

  Future<Either<Failure, void>> call(String versionId, String targetStatus) =>
      _repository.promoteVersion(versionId, targetStatus);
}

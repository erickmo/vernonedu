import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_version_repository.dart';

class UpsertInternshipConfigUseCase {
  final CourseVersionRepository _repository;
  const UpsertInternshipConfigUseCase(this._repository);

  Future<Either<Failure, void>> call(String versionId, Map<String, dynamic> data) =>
      _repository.upsertInternshipConfig(versionId, data);
}

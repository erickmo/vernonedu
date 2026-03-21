import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/internship_config_entity.dart';
import '../repositories/course_version_repository.dart';

class GetInternshipConfigUseCase {
  final CourseVersionRepository _repository;
  const GetInternshipConfigUseCase(this._repository);

  Future<Either<Failure, InternshipConfigEntity?>> call(String versionId) =>
      _repository.getInternshipConfig(versionId);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_version_repository.dart';

class UpsertCharacterTestConfigUseCase {
  final CourseVersionRepository _repository;
  const UpsertCharacterTestConfigUseCase(this._repository);

  Future<Either<Failure, void>> call(String versionId, Map<String, dynamic> data) =>
      _repository.upsertCharacterTestConfig(versionId, data);
}

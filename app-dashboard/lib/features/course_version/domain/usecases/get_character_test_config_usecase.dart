import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/character_test_config_entity.dart';
import '../repositories/course_version_repository.dart';

class GetCharacterTestConfigUseCase {
  final CourseVersionRepository _repository;
  const GetCharacterTestConfigUseCase(this._repository);

  Future<Either<Failure, CharacterTestConfigEntity?>> call(String versionId) =>
      _repository.getCharacterTestConfig(versionId);
}

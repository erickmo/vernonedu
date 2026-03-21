import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_module_entity.dart';
import '../repositories/course_module_repository.dart';

class GetCourseModulesUseCase {
  final CourseModuleRepository _repository;
  const GetCourseModulesUseCase(this._repository);

  Future<Either<Failure, List<CourseModuleEntity>>> call(String versionId) =>
      _repository.getModulesByVersion(versionId);
}

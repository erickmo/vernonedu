import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_module_repository.dart';

class CreateCourseModuleUseCase {
  final CourseModuleRepository _repository;
  const CreateCourseModuleUseCase(this._repository);

  Future<Either<Failure, void>> call(String versionId, Map<String, dynamic> data) =>
      _repository.createModule(versionId, data);
}

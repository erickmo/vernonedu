import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_module_repository.dart';

class UpdateCourseModuleUseCase {
  final CourseModuleRepository _repository;
  const UpdateCourseModuleUseCase(this._repository);

  Future<Either<Failure, void>> call(String moduleId, Map<String, dynamic> data) =>
      _repository.updateModule(moduleId, data);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_module_repository.dart';

class DeleteCourseModuleUseCase {
  final CourseModuleRepository _repository;
  const DeleteCourseModuleUseCase(this._repository);

  Future<Either<Failure, void>> call(String moduleId) =>
      _repository.deleteModule(moduleId);
}

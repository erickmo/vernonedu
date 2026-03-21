import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_repository.dart';

class DeleteCourseUseCase {
  final CourseRepository _repository;
  const DeleteCourseUseCase(this._repository);
  Future<Either<Failure, void>> call(String id) => _repository.deleteCourse(id);
}

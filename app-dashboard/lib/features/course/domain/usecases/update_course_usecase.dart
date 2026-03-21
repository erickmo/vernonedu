import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_repository.dart';

class UpdateCourseUseCase {
  final CourseRepository _repository;
  const UpdateCourseUseCase(this._repository);
  Future<Either<Failure, void>> call(String id, Map<String, dynamic> data) =>
      _repository.updateCourse(id, data);
}

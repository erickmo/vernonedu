import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_repository.dart';

class CreateCourseUseCase {
  final CourseRepository _repository;
  const CreateCourseUseCase(this._repository);
  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createCourse(data);
}

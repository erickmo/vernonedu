import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_type_repository.dart';

// Use case untuk membuat tipe course baru di bawah master course tertentu
class CreateCourseTypeUseCase {
  final CourseTypeRepository _repository;
  const CreateCourseTypeUseCase(this._repository);

  Future<Either<Failure, void>> call(String courseId, Map<String, dynamic> data) =>
      _repository.createType(courseId, data);
}

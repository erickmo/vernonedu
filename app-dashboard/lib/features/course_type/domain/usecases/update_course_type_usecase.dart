import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_type_repository.dart';

// Use case untuk mengupdate data tipe course
class UpdateCourseTypeUseCase {
  final CourseTypeRepository _repository;
  const UpdateCourseTypeUseCase(this._repository);

  Future<Either<Failure, void>> call(String typeId, Map<String, dynamic> data) =>
      _repository.updateType(typeId, data);
}

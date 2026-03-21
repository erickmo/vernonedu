import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_type_repository.dart';

// Use case untuk toggle aktif/nonaktif tipe course
class ToggleCourseTypeUseCase {
  final CourseTypeRepository _repository;
  const ToggleCourseTypeUseCase(this._repository);

  Future<Either<Failure, void>> call(String typeId) =>
      _repository.toggleType(typeId);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_version_repository.dart';

// Use case untuk membuat versi baru di bawah tipe course tertentu
class CreateCourseVersionUseCase {
  final CourseVersionRepository _repository;
  const CreateCourseVersionUseCase(this._repository);

  Future<Either<Failure, void>> call(String typeId, Map<String, dynamic> data) =>
      _repository.createVersion(typeId, data);
}

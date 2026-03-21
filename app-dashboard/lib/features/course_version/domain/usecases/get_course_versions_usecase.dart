import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_version_entity.dart';
import '../repositories/course_version_repository.dart';

// Use case untuk mengambil daftar versi berdasarkan type ID
class GetCourseVersionsUseCase {
  final CourseVersionRepository _repository;
  const GetCourseVersionsUseCase(this._repository);

  Future<Either<Failure, List<CourseVersionEntity>>> call(String typeId) =>
      _repository.getVersionsByType(typeId);
}

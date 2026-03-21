import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_type_entity.dart';
import '../repositories/course_type_repository.dart';

// Use case untuk mengambil daftar tipe berdasarkan master course ID
class GetCourseTypesUseCase {
  final CourseTypeRepository _repository;
  const GetCourseTypesUseCase(this._repository);

  Future<Either<Failure, List<CourseTypeEntity>>> call(String courseId) =>
      _repository.getTypesByCourse(courseId);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_type_entity.dart';

// Kontrak repository domain untuk CourseType
abstract class CourseTypeRepository {
  Future<Either<Failure, List<CourseTypeEntity>>> getTypesByCourse(String courseId);
  Future<Either<Failure, CourseTypeEntity>> getTypeById(String typeId);
  Future<Either<Failure, void>> createType(String courseId, Map<String, dynamic> data);
  Future<Either<Failure, void>> updateType(String typeId, Map<String, dynamic> data);
  Future<Either<Failure, void>> toggleType(String typeId);
}

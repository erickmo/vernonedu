import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_module_entity.dart';

// Kontrak repository domain untuk CourseModule
abstract class CourseModuleRepository {
  Future<Either<Failure, List<CourseModuleEntity>>> getModulesByVersion(String versionId);
  Future<Either<Failure, void>> createModule(String versionId, Map<String, dynamic> data);
  Future<Either<Failure, void>> updateModule(String moduleId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteModule(String moduleId);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_entity.dart';

// Kontrak repository domain untuk MasterCourse
abstract class CourseRepository {
  Future<Either<Failure, List<CourseEntity>>> getCourses({
    int offset = 0,
    int limit = 20,
    String status = '',
    String field = '',
  });
  Future<Either<Failure, CourseEntity>> getCourseById(String id);
  Future<Either<Failure, void>> createCourse(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateCourse(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> archiveCourse(String id);
  Future<Either<Failure, void>> deleteCourse(String id);
}

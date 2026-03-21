import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_course_entity.dart';
import '../repositories/department_repository.dart';

class GetDepartmentCoursesUseCase {
  final DepartmentRepository repository;
  const GetDepartmentCoursesUseCase(this.repository);

  Future<Either<Failure, List<DepartmentCourseEntity>>> call(String departmentId) =>
      repository.getDepartmentCourses(departmentId);
}

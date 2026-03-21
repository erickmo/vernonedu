import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_student_entity.dart';
import '../repositories/department_repository.dart';

class GetDepartmentStudentsUseCase {
  final DepartmentRepository repository;
  const GetDepartmentStudentsUseCase(this.repository);

  Future<Either<Failure, List<DepartmentStudentEntity>>> call(String departmentId, {String status = ''}) =>
      repository.getDepartmentStudents(departmentId, status: status);
}

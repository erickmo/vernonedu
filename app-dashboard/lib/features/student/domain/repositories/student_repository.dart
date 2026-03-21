import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/student_entity.dart';

abstract class StudentRepository {
  Future<Either<Failure, List<StudentEntity>>> getStudents({int offset = 0, int limit = 20});
  Future<Either<Failure, void>> createStudent({
    required String name,
    required String email,
    String phone = '',
    String departmentId = '',
  });
  Future<Either<Failure, void>> deleteStudent(String id);
}

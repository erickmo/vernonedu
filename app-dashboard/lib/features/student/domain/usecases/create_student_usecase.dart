import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/student_repository.dart';

class CreateStudentUseCase {
  final StudentRepository _repository;
  const CreateStudentUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String name,
    required String email,
    String phone = '',
    String departmentId = '',
  }) =>
      _repository.createStudent(
        name: name,
        email: email,
        phone: phone,
        departmentId: departmentId,
      );
}

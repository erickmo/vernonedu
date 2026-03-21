import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/student_detail_repository.dart';

class UpdateStudentUseCase {
  final StudentDetailRepository _repository;
  const UpdateStudentUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String id, {
    required String name,
    required String email,
    required String phone,
  }) =>
      _repository.updateStudent(id, name: name, email: email, phone: phone);
}

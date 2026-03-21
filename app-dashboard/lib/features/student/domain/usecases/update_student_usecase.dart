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
    String? nik,
    String? gender,
    String? address,
    String? birthDate,
    String? departmentId,
    String status = 'aktif',
    String? studentCode,
  }) =>
      _repository.updateStudent(
        id,
        name: name,
        email: email,
        phone: phone,
        nik: nik,
        gender: gender,
        address: address,
        birthDate: birthDate,
        departmentId: departmentId,
        status: status,
        studentCode: studentCode,
      );
}

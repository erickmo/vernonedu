import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/student_crm_log_entity.dart';
import '../repositories/student_detail_repository.dart';

class AddStudentCrmLogUseCase {
  final StudentDetailRepository _repository;
  const AddStudentCrmLogUseCase(this._repository);

  Future<Either<Failure, StudentCrmLogEntity>> call(
    String studentId, {
    required String contactMethod,
    required String response,
    String? contactedBy,
  }) =>
      _repository.addStudentCrmLog(
        studentId,
        contactMethod: contactMethod,
        response: response,
        contactedBy: contactedBy,
      );
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/student_crm_log_entity.dart';
import '../repositories/student_detail_repository.dart';

class GetStudentCrmLogsUseCase {
  final StudentDetailRepository _repository;
  const GetStudentCrmLogsUseCase(this._repository);

  Future<Either<Failure, List<StudentCrmLogEntity>>> call(String studentId) =>
      _repository.getStudentCrmLogs(studentId);
}

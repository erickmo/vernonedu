import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/student_detail_entity.dart';
import '../repositories/student_detail_repository.dart';

class GetStudentDetailUseCase {
  final StudentDetailRepository _repository;

  const GetStudentDetailUseCase(this._repository);

  Future<Either<Failure, StudentDetailEntity>> call(String studentId) {
    return _repository.getStudentDetail(studentId);
  }
}

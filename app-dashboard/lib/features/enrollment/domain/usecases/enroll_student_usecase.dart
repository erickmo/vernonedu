import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/enrollment_repository.dart';

class EnrollStudentUseCase {
  final EnrollmentRepository _repository;
  const EnrollStudentUseCase(this._repository);
  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.enrollStudent(data);
}

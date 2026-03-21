import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/enrollment_repository.dart';

class UpdateEnrollmentStatusUseCase {
  final EnrollmentRepository _repository;
  const UpdateEnrollmentStatusUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, String status) =>
      _repository.updateEnrollmentStatus(id, status);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/enrollment_repository.dart';

class UpdateEnrollmentPaymentStatusUseCase {
  final EnrollmentRepository _repository;
  const UpdateEnrollmentPaymentStatusUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, String paymentStatus) =>
      _repository.updateEnrollmentPaymentStatus(id, paymentStatus);
}

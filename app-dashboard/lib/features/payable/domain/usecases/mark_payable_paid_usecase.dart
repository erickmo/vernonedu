import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/payable_repository.dart';

class MarkPayablePaidUseCase {
  final PayableRepository repository;
  const MarkPayablePaidUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String id, {
    String? paymentProof,
  }) =>
      repository.markPayableAsPaid(id, paymentProof: paymentProof);
}

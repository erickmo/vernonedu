import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/payable_entity.dart';

abstract class PayableRepository {
  Future<Either<Failure, PayableStatsEntity>> getPayableStats();

  Future<Either<Failure, List<PayableEntity>>> getPayables({
    int offset = 0,
    int limit = 20,
    String? type,
    String? status,
    String? batchId,
  });

  Future<Either<Failure, PayableEntity>> getPayableById(String id);

  Future<Either<Failure, void>> markPayableAsPaid(
    String id, {
    String? paymentProof,
  });
}

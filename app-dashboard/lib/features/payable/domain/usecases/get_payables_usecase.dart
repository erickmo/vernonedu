import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/payable_entity.dart';
import '../repositories/payable_repository.dart';

class GetPayablesUseCase {
  final PayableRepository repository;
  const GetPayablesUseCase(this.repository);

  Future<Either<Failure, List<PayableEntity>>> call({
    int offset = 0,
    int limit = 20,
    String? type,
    String? status,
    String? batchId,
  }) =>
      repository.getPayables(
        offset: offset,
        limit: limit,
        type: type,
        status: status,
        batchId: batchId,
      );
}

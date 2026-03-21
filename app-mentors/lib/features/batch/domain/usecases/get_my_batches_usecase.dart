import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/batch_entity.dart';
import '../repositories/batch_repository.dart';

class GetMyBatchesUseCase {
  final BatchRepository _repository;

  const GetMyBatchesUseCase(this._repository);

  Future<Either<Failure, List<BatchEntity>>> call() =>
      _repository.getMyBatches();
}

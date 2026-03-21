import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/batch_detail_entity.dart';
import '../repositories/batch_repository.dart';

class GetBatchDetailUseCase {
  final BatchRepository _repository;

  const GetBatchDetailUseCase(this._repository);

  Future<Either<Failure, BatchDetailEntity>> call(String batchId) =>
      _repository.getBatchDetail(batchId);
}

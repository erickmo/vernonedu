import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/batch_detail_entity.dart';
import '../entities/batch_entity.dart';

abstract class BatchRepository {
  Future<Either<Failure, List<BatchEntity>>> getMyBatches();
  Future<Either<Failure, BatchDetailEntity>> getBatchDetail(String batchId);
  Future<Either<Failure, void>> assignFacilitator(
      String batchId, String facilitatorId);
}

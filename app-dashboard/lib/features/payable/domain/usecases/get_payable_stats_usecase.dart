import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/payable_entity.dart';
import '../repositories/payable_repository.dart';

class GetPayableStatsUseCase {
  final PayableRepository repository;
  const GetPayableStatsUseCase(this.repository);

  Future<Either<Failure, PayableStatsEntity>> call() =>
      repository.getPayableStats();
}

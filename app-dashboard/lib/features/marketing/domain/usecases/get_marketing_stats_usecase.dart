import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/marketing_stats_entity.dart';
import '../repositories/marketing_repository.dart';

class GetMarketingStatsUseCase {
  final MarketingRepository _repository;
  const GetMarketingStatsUseCase(this._repository);

  Future<Either<Failure, MarketingStatsEntity>> call() =>
      _repository.getStats();
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/accounting_stats_entity.dart';
import '../repositories/accounting_repository.dart';

class GetAccountingStatsUseCase {
  final AccountingRepository _repository;
  const GetAccountingStatsUseCase(this._repository);

  Future<Either<Failure, AccountingStatsEntity>> call({
    required int month,
    required int year,
  }) =>
      _repository.getStats(month: month, year: year);
}

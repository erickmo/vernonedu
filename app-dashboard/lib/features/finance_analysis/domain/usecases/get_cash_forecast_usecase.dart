import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_analysis_entity.dart';
import '../repositories/finance_analysis_repository.dart';

class GetCashForecastUseCase {
  final FinanceAnalysisRepository repository;
  GetCashForecastUseCase(this.repository);

  Future<Either<Failure, CashForecastEntity>> call({
    int months = 3,
    String? branchId,
  }) =>
      repository.getCashForecast(months: months, branchId: branchId);
}

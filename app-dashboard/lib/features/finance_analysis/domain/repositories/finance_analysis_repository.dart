import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_analysis_entity.dart';

abstract class FinanceAnalysisRepository {
  Future<Either<Failure, FinancialRatioEntity>> getRatios({
    String period,
    String? branchId,
    String comparison,
  });

  Future<Either<Failure, RevenueAnalysisEntity>> getRevenue({
    String period,
    String? branchId,
    String groupBy,
  });

  Future<Either<Failure, CostAnalysisEntity>> getCosts({
    String period,
    String? branchId,
    String groupBy,
  });

  Future<Either<Failure, BatchProfitAnalysisEntity>> getBatchProfit({
    String period,
    String? branchId,
    int limit,
  });

  Future<Either<Failure, CashForecastEntity>> getCashForecast({
    int months,
    String? branchId,
  });

  Future<Either<Failure, List<FinanceAlertEntity>>> getAlerts();
  Future<Either<Failure, List<FinanceAlertEntity>>> getSuggestions();
}

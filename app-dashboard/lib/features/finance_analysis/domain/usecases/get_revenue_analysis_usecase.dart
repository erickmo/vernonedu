import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_analysis_entity.dart';
import '../repositories/finance_analysis_repository.dart';

class GetRevenueAnalysisUseCase {
  final FinanceAnalysisRepository repository;
  GetRevenueAnalysisUseCase(this.repository);

  Future<Either<Failure, RevenueAnalysisEntity>> call({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) =>
      repository.getRevenue(
        period: period,
        branchId: branchId,
        groupBy: groupBy,
      );
}

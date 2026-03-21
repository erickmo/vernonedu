import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_analysis_entity.dart';
import '../repositories/finance_analysis_repository.dart';

class GetBatchProfitAnalysisUseCase {
  final FinanceAnalysisRepository repository;
  GetBatchProfitAnalysisUseCase(this.repository);

  Future<Either<Failure, BatchProfitAnalysisEntity>> call({
    String period = 'monthly',
    String? branchId,
    int limit = 10,
  }) =>
      repository.getBatchProfit(
        period: period,
        branchId: branchId,
        limit: limit,
      );
}

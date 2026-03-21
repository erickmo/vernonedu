import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_analysis_entity.dart';
import '../repositories/finance_analysis_repository.dart';

class GetCostAnalysisUseCase {
  final FinanceAnalysisRepository repository;
  GetCostAnalysisUseCase(this.repository);

  Future<Either<Failure, CostAnalysisEntity>> call({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) =>
      repository.getCosts(
        period: period,
        branchId: branchId,
        groupBy: groupBy,
      );
}

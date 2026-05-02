import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_analysis_entity.dart';
import '../repositories/finance_analysis_repository.dart';

class GetFinancialRatiosUseCase {
  final FinanceAnalysisRepository repository;
  GetFinancialRatiosUseCase(this.repository);

  Future<Either<Failure, FinancialRatiosEntity>> call({
    String period = 'monthly',
    String? branchId,
    String comparison = 'prev_month',
  }) =>
      repository.getRatios(
        period: period,
        branchId: branchId,
        comparison: comparison,
      );
}

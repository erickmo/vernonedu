import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_analysis_entity.dart';
import '../repositories/finance_analysis_repository.dart';

class GetFinanceAlertsUseCase {
  final FinanceAnalysisRepository repository;
  GetFinanceAlertsUseCase(this.repository);

  Future<Either<Failure, List<FinanceAlertEntity>>> call() =>
      repository.getAlerts();
}

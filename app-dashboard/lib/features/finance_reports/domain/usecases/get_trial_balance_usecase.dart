import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_filter_entity.dart';
import '../entities/trial_balance_entity.dart';
import '../repositories/finance_reports_repository.dart';

class GetTrialBalanceUseCase {
  final FinanceReportsRepository _repository;
  const GetTrialBalanceUseCase(this._repository);

  Future<Either<Failure, TrialBalanceEntity>> call(ReportFilterEntity filter) =>
      _repository.getTrialBalance(filter);
}

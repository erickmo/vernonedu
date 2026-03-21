import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profit_loss_entity.dart';
import '../entities/report_filter_entity.dart';
import '../repositories/finance_reports_repository.dart';

class GetProfitLossUseCase {
  final FinanceReportsRepository _repository;
  const GetProfitLossUseCase(this._repository);

  Future<Either<Failure, ProfitLossEntity>> call(ReportFilterEntity filter) =>
      _repository.getProfitLoss(filter);
}

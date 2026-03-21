import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cash_flow_entity.dart';
import '../entities/report_filter_entity.dart';
import '../repositories/finance_reports_repository.dart';

class GetCashFlowUseCase {
  final FinanceReportsRepository _repository;
  const GetCashFlowUseCase(this._repository);

  Future<Either<Failure, CashFlowEntity>> call(ReportFilterEntity filter) =>
      _repository.getCashFlow(filter);
}

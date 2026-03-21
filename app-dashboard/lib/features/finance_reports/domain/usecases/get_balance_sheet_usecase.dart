import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/balance_sheet_entity.dart';
import '../entities/report_filter_entity.dart';
import '../repositories/finance_reports_repository.dart';

class GetBalanceSheetUseCase {
  final FinanceReportsRepository _repository;
  const GetBalanceSheetUseCase(this._repository);

  Future<Either<Failure, BalanceSheetEntity>> call(ReportFilterEntity filter) =>
      _repository.getBalanceSheet(filter);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ledger_entity.dart';
import '../entities/report_filter_entity.dart';
import '../repositories/finance_reports_repository.dart';

class GetLedgerUseCase {
  final FinanceReportsRepository _repository;
  const GetLedgerUseCase(this._repository);

  Future<Either<Failure, LedgerEntity>> call({
    required ReportFilterEntity filter,
    String? accountId,
  }) =>
      _repository.getLedger(filter: filter, accountId: accountId);
}

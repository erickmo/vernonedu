import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/balance_sheet_entity.dart';
import '../entities/cash_flow_entity.dart';
import '../entities/ledger_entity.dart';
import '../entities/profit_loss_entity.dart';
import '../entities/report_filter_entity.dart';
import '../entities/trial_balance_entity.dart';

abstract class FinanceReportsRepository {
  Future<Either<Failure, BalanceSheetEntity>> getBalanceSheet(ReportFilterEntity filter);

  Future<Either<Failure, ProfitLossEntity>> getProfitLoss(ReportFilterEntity filter);

  Future<Either<Failure, CashFlowEntity>> getCashFlow(ReportFilterEntity filter);

  Future<Either<Failure, LedgerEntity>> getLedger({
    required ReportFilterEntity filter,
    String? accountId,
  });

  Future<Either<Failure, TrialBalanceEntity>> getTrialBalance(ReportFilterEntity filter);
}

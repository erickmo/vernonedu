import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/accounting_stats_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/invoice_entity.dart';
import '../entities/coa_entity.dart';
import '../entities/budget_item_entity.dart';

abstract class AccountingRepository {
  Future<Either<Failure, AccountingStatsEntity>> getStats({
    required int month,
    required int year,
  });

  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? type,
  });

  Future<Either<Failure, void>> createTransaction({
    required Map<String, dynamic> body,
  });

  Future<Either<Failure, List<InvoiceEntity>>> getInvoices({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? status,
  });

  Future<Either<Failure, void>> updateInvoiceStatus({
    required String id,
    required String status,
  });

  Future<Either<Failure, List<CoaEntity>>> getCoa();

  Future<Either<Failure, List<BudgetItemEntity>>> getBudgetVsActual({
    required int month,
    required int year,
  });
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/accounting_repository.dart';

class GetTransactionsUseCase {
  final AccountingRepository _repository;
  const GetTransactionsUseCase(this._repository);

  Future<Either<Failure, List<TransactionEntity>>> call({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? type,
  }) =>
      _repository.getTransactions(
        offset: offset,
        limit: limit,
        month: month,
        year: year,
        type: type,
      );
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/accounting_repository.dart';

class UpdateTransactionUseCase {
  final AccountingRepository _repository;
  const UpdateTransactionUseCase(this._repository);

  Future<Either<Failure, TransactionEntity>> call({
    required String id,
    required String description,
    String? category,
  }) =>
      _repository.updateTransaction(
        id: id,
        description: description,
        category: category,
      );
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/accounting_repository.dart';

class DeleteTransactionUseCase {
  final AccountingRepository _repository;
  const DeleteTransactionUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteTransaction(id);
}

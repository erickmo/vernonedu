import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/accounting_repository.dart';

class DeleteBankAccountUseCase {
  final AccountingRepository _repository;
  const DeleteBankAccountUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteBankAccount(id);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bank_account_entity.dart';
import '../repositories/accounting_repository.dart';

class UpdateBankAccountUseCase {
  final AccountingRepository _repository;
  const UpdateBankAccountUseCase(this._repository);

  Future<Either<Failure, void>> call(BankAccountEntity account) =>
      _repository.updateBankAccount(account);
}

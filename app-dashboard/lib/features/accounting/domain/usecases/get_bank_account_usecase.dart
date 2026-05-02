import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bank_account_entity.dart';
import '../repositories/accounting_repository.dart';

class GetBankAccountUseCase {
  final AccountingRepository _repository;
  const GetBankAccountUseCase(this._repository);

  Future<Either<Failure, BankAccountEntity>> call(String id) =>
      _repository.getBankAccount(id);
}

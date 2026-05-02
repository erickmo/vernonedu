import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bank_account_entity.dart';
import '../repositories/accounting_repository.dart';

class ListBankAccountsUseCase {
  final AccountingRepository _repository;
  const ListBankAccountsUseCase(this._repository);

  Future<Either<Failure, List<BankAccountEntity>>> call({
    String? branchId,
    bool includeInactive = false,
  }) =>
      _repository.listBankAccounts(
        branchId: branchId,
        includeInactive: includeInactive,
      );
}

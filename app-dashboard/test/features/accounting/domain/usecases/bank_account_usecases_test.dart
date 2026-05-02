import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/bank_account_entity.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/create_bank_account_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/delete_bank_account_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_bank_account_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/list_bank_accounts_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/update_bank_account_usecase.dart';

class _MockRepo extends Mock implements AccountingRepository {}

const _entity = BankAccountEntity(
  id: '1',
  branchId: 'b',
  name: 'Kas',
  bankName: '',
  accountNumber: '',
  balanceCents: 0,
  currency: 'IDR',
  coaCode: '',
  isActive: true,
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(_entity);
  });

  test('ListBankAccountsUseCase delegates to repository', () async {
    when(() => repo.listBankAccounts(
          branchId: any(named: 'branchId'),
          includeInactive: any(named: 'includeInactive'),
        )).thenAnswer((_) async => const Right([_entity]));

    final result = await ListBankAccountsUseCase(repo)();

    expect(result.isRight(), true);
    verify(() => repo.listBankAccounts(includeInactive: false)).called(1);
  });

  test('GetBankAccountUseCase delegates to repository', () async {
    when(() => repo.getBankAccount(any()))
        .thenAnswer((_) async => const Right(_entity));

    final result = await GetBankAccountUseCase(repo)('1');

    expect(result.isRight(), true);
    verify(() => repo.getBankAccount('1')).called(1);
  });

  test('CreateBankAccountUseCase delegates to repository', () async {
    when(() => repo.createBankAccount(any()))
        .thenAnswer((_) async => const Right(null));

    final result = await CreateBankAccountUseCase(repo)(_entity);

    expect(result.isRight(), true);
    verify(() => repo.createBankAccount(_entity)).called(1);
  });

  test('UpdateBankAccountUseCase delegates to repository', () async {
    when(() => repo.updateBankAccount(any()))
        .thenAnswer((_) async => const Right(null));

    final result = await UpdateBankAccountUseCase(repo)(_entity);

    expect(result.isRight(), true);
    verify(() => repo.updateBankAccount(_entity)).called(1);
  });

  test('DeleteBankAccountUseCase delegates to repository', () async {
    when(() => repo.deleteBankAccount(any()))
        .thenAnswer((_) async => const Right(null));

    final result = await DeleteBankAccountUseCase(repo)('1');

    expect(result.isRight(), true);
    verify(() => repo.deleteBankAccount('1')).called(1);
  });
}

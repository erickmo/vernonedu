import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/transaction_entity.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/delete_transaction_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/update_transaction_usecase.dart';

class _MockRepo extends Mock implements AccountingRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('UpdateTransactionUseCase delegates to repo.updateTransaction', () async {
    const entity = TransactionEntity(
      id: 'tx-1',
      referenceNumber: 'TR-001',
      description: 'Edited',
      transactionType: 'income',
      amount: 1000,
      category: 'Cat',
      transactionDate: '2026-05-01',
      status: 'completed',
    );
    when(() => repo.updateTransaction(
          id: any(named: 'id'),
          description: any(named: 'description'),
          category: any(named: 'category'),
        )).thenAnswer((_) async => const Right(entity));

    final uc = UpdateTransactionUseCase(repo);
    final result =
        await uc(id: 'tx-1', description: 'Edited', category: 'Cat');

    expect(result.isRight(), true);
    expect(
      result.getOrElse(() => throw Exception('expected Right')),
      entity,
    );
    verify(() => repo.updateTransaction(
          id: 'tx-1',
          description: 'Edited',
          category: 'Cat',
        )).called(1);
  });

  test('DeleteTransactionUseCase delegates to repo.deleteTransaction', () async {
    when(() => repo.deleteTransaction(any()))
        .thenAnswer((_) async => const Right(null));

    final uc = DeleteTransactionUseCase(repo);
    final result = await uc('tx-1');

    expect(result.isRight(), true);
    verify(() => repo.deleteTransaction('tx-1')).called(1);
  });
}

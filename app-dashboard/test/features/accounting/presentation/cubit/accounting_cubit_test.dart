import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/accounting_stats_entity.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/transaction_entity.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/create_transaction_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/delete_transaction_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_accounting_stats_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_budget_vs_actual_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_coa_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_invoices_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_transactions_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/update_invoice_status_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/update_transaction_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/presentation/cubit/accounting_cubit.dart';

class _MockGetStats extends Mock implements GetAccountingStatsUseCase {}

class _MockGetTx extends Mock implements GetTransactionsUseCase {}

class _MockCreateTx extends Mock implements CreateTransactionUseCase {}

class _MockUpdateTx extends Mock implements UpdateTransactionUseCase {}

class _MockDeleteTx extends Mock implements DeleteTransactionUseCase {}

class _MockGetInv extends Mock implements GetInvoicesUseCase {}

class _MockUpdInv extends Mock implements UpdateInvoiceStatusUseCase {}

class _MockGetCoa extends Mock implements GetCoaUseCase {}

class _MockGetBudget extends Mock implements GetBudgetVsActualUseCase {}

const _txEntity = TransactionEntity(
  id: 'tx-1',
  referenceNumber: 'TR-001',
  description: 'Edited',
  transactionType: 'income',
  amount: 1000,
  category: 'Cat',
  transactionDate: '2026-05-01',
  status: 'completed',
);

void main() {
  late _MockGetStats getStats;
  late _MockGetTx getTx;
  late _MockCreateTx createTx;
  late _MockUpdateTx updateTx;
  late _MockDeleteTx deleteTx;
  late _MockGetInv getInv;
  late _MockUpdInv updInv;
  late _MockGetCoa getCoa;
  late _MockGetBudget getBudget;

  AccountingCubit build() => AccountingCubit(
        getStatsUseCase: getStats,
        getTransactionsUseCase: getTx,
        createTransactionUseCase: createTx,
        updateTransactionUseCase: updateTx,
        deleteTransactionUseCase: deleteTx,
        getInvoicesUseCase: getInv,
        updateInvoiceStatusUseCase: updInv,
        getCoaUseCase: getCoa,
        getBudgetVsActualUseCase: getBudget,
      );

  void stubLoadAllOk() {
    when(() => getStats(month: any(named: 'month'), year: any(named: 'year')))
        .thenAnswer((_) async => const Right(AccountingStatsEntity(
              totalRevenue: 0,
              totalExpense: 0,
              netProfit: 0,
              cashAndBank: 0,
              receivables: 0,
              payables: 0,
            )));
    when(() => getTx(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Right([]));
    when(() => getInv(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Right([]));
    when(() => getCoa()).thenAnswer((_) async => const Right([]));
    when(() => getBudget(
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Right([]));
  }

  setUp(() {
    getStats = _MockGetStats();
    getTx = _MockGetTx();
    createTx = _MockCreateTx();
    updateTx = _MockUpdateTx();
    deleteTx = _MockDeleteTx();
    getInv = _MockGetInv();
    updInv = _MockUpdInv();
    getCoa = _MockGetCoa();
    getBudget = _MockGetBudget();
    stubLoadAllOk();
  });

  test('updateTransaction success triggers reload and returns true', () async {
    when(() => updateTx(
          id: any(named: 'id'),
          description: any(named: 'description'),
          category: any(named: 'category'),
        )).thenAnswer((_) async => const Right(_txEntity));

    final cubit = build();
    final ok = await cubit.updateTransaction(
      id: 'tx-1',
      description: 'Edited',
      category: 'Cat',
    );

    expect(ok, true);
    verify(() => updateTx(
          id: 'tx-1',
          description: 'Edited',
          category: 'Cat',
        )).called(1);
    // loadAll triggered after success
    verify(() => getStats(month: any(named: 'month'), year: any(named: 'year')))
        .called(1);
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
  });

  test('updateTransaction failure emits error and returns false', () async {
    when(() => updateTx(
          id: any(named: 'id'),
          description: any(named: 'description'),
          category: any(named: 'category'),
        )).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final cubit = build();
    final ok = await cubit.updateTransaction(
      id: 'tx-1',
      description: 'Edited',
      category: 'Cat',
    );

    expect(ok, false);
    expect(cubit.state, isA<AccountingError>());
    expect((cubit.state as AccountingError).message, 'boom');
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
  });

  test('deleteTransaction success triggers reload and returns true', () async {
    when(() => deleteTx(any())).thenAnswer((_) async => const Right(null));

    final cubit = build();
    final ok = await cubit.deleteTransaction('tx-1');

    expect(ok, true);
    verify(() => deleteTx('tx-1')).called(1);
    verify(() => getStats(month: any(named: 'month'), year: any(named: 'year')))
        .called(1);
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
  });

  test('deleteTransaction failure emits error and returns false', () async {
    when(() => deleteTx(any()))
        .thenAnswer((_) async => const Left(ServerFailure('nope')));

    final cubit = build();
    final ok = await cubit.deleteTransaction('tx-1');

    expect(ok, false);
    expect(cubit.state, isA<AccountingError>());
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
  });
}

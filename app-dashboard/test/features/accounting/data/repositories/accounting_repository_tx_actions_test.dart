import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/core/network/network_info.dart';
import 'package:vernonedu_dashboard/features/accounting/data/datasources/accounting_remote_datasource.dart';
import 'package:vernonedu_dashboard/features/accounting/data/models/transaction_model.dart';
import 'package:vernonedu_dashboard/features/accounting/data/repositories/accounting_repository_impl.dart';

class _MockDataSource extends Mock implements AccountingRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockDataSource ds;
  late _MockNetworkInfo network;
  late AccountingRepositoryImpl repo;

  setUp(() {
    ds = _MockDataSource();
    network = _MockNetworkInfo();
    repo = AccountingRepositoryImpl(remoteDataSource: ds, networkInfo: network);
    when(() => network.isConnected).thenAnswer((_) async => true);
  });

  test('updateTransaction returns Right(entity) on success', () async {
    when(() => ds.updateTransaction(any(), any())).thenAnswer(
      (_) async => const TransactionModel(
        id: 'tx-1',
        referenceNumber: 'TR-001',
        description: 'Updated desc',
        transactionType: 'income',
        amount: 100000,
        category: 'Pendapatan',
        transactionDate: '2026-05-01',
        status: 'completed',
      ),
    );

    final result = await repo.updateTransaction(
      id: 'tx-1',
      description: 'Updated desc',
      category: 'Pendapatan',
    );

    expect(result.isRight(), true);
    final entity = result.getOrElse(() => throw Exception('expected Right'));
    expect(entity.id, 'tx-1');
    expect(entity.description, 'Updated desc');
    expect(entity.category, 'Pendapatan');
    verify(() => ds.updateTransaction('tx-1', {
          'description': 'Updated desc',
          'category': 'Pendapatan',
        })).called(1);
  });

  test('deleteTransaction returns Left(ServerFailure) on DioException', () async {
    when(() => ds.deleteTransaction(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
          data: {'error': 'boom'},
        ),
        message: 'fail',
      ),
    );

    final result = await repo.deleteTransaction('tx-1');

    expect(result.isLeft(), true);
    final failure = result.fold((l) => l, (_) => null);
    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).message, 'boom');
  });
}

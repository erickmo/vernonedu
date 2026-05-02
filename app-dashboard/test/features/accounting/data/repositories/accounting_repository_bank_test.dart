import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/core/network/network_info.dart';
import 'package:vernonedu_dashboard/features/accounting/data/datasources/accounting_remote_datasource.dart';
import 'package:vernonedu_dashboard/features/accounting/data/models/bank_account_model.dart';
import 'package:vernonedu_dashboard/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/bank_account_entity.dart';

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

  test('listBankAccounts returns Right(list) on success', () async {
    when(() => ds.listBankAccounts(
          branchId: any(named: 'branchId'),
          includeInactive: any(named: 'includeInactive'),
        )).thenAnswer((_) async => [
          const BankAccountModel(
            id: '1',
            branchId: 'b',
            name: 'Kas',
            bankName: '',
            accountNumber: '',
            balanceCents: 0,
            currency: 'IDR',
            coaCode: '',
            isActive: true,
          ),
        ]);

    final result = await repo.listBankAccounts();

    expect(result.isRight(), true);
    final items = result.getOrElse(() => <BankAccountEntity>[]);
    expect(items.length, 1);
    expect(items.first.name, 'Kas');
  });

  test('deleteBankAccount returns Left(ServerFailure) on DioException', () async {
    when(() => ds.deleteBankAccount(any())).thenThrow(
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

    final result = await repo.deleteBankAccount('1');

    expect(result.isLeft(), true);
    final failure = result.fold((l) => l, (_) => null);
    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).message, 'boom');
  });
}

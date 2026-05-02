import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/core/network/network_info.dart';
import 'package:vernonedu_dashboard/features/accounting/data/datasources/accounting_remote_datasource.dart';
import 'package:vernonedu_dashboard/features/accounting/data/models/coa_tree_node_model.dart';
import 'package:vernonedu_dashboard/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/coa_tree_node_entity.dart';

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

  test('getCoaTree returns Right(list) on success', () async {
    when(() => ds.getCoaTree()).thenAnswer((_) async => [
          const CoaTreeNodeModel(
            id: '1',
            code: '1',
            name: 'Aset',
            accountType: 'asset',
            parentCode: '',
            isActive: true,
          ),
        ]);

    final result = await repo.getCoaTree();

    expect(result.isRight(), true);
    final items = result.getOrElse(() => <CoaTreeNodeEntity>[]);
    expect(items.length, 1);
    expect(items.first.code, '1');
  });

  test('getCoaTree returns Left(ServerFailure) on DioException', () async {
    when(() => ds.getCoaTree()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
          data: {'error': 'tree boom'},
        ),
        message: 'fail',
      ),
    );

    final result = await repo.getCoaTree();

    expect(result.isLeft(), true);
    final failure = result.fold((l) => l, (_) => null);
    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).message, 'tree boom');
  });
}

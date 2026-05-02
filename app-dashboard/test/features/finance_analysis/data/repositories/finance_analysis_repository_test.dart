import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/core/network/network_info.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/data/datasources/finance_analysis_remote_datasource.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/data/models/finance_analysis_model.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/data/repositories/finance_analysis_repository_impl.dart';

class _MockDs extends Mock implements FinanceAnalysisRemoteDataSource {}

class _MockNet extends Mock implements NetworkInfo {}

void main() {
  late _MockDs ds;
  late _MockNet net;
  late FinanceAnalysisRepositoryImpl repo;

  setUp(() {
    ds = _MockDs();
    net = _MockNet();
    repo = FinanceAnalysisRepositoryImpl(
      remoteDataSource: ds,
      networkInfo: net,
    );
    when(() => net.isConnected).thenAnswer((_) async => true);
  });

  test('getRatios returns Right on success', () async {
    when(() => ds.fetchRatios(
          period: any(named: 'period'),
          branchId: any(named: 'branchId'),
          comparison: any(named: 'comparison'),
        )).thenAnswer((_) async => FinancialRatiosModel.fromJson({
          'profit_margin': {'current': 10.0},
        }));

    final result = await repo.getRatios();

    expect(result.isRight(), true);
    result.fold(
      (_) => fail('expected Right'),
      (e) => expect(e.profitMargin.current, 10.0),
    );
  });

  test('getRatios returns Left(ServerFailure) on DioException', () async {
    when(() => ds.fetchRatios(
          period: any(named: 'period'),
          branchId: any(named: 'branchId'),
          comparison: any(named: 'comparison'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/finance/analysis/ratios'),
      response: Response(
        requestOptions: RequestOptions(path: '/finance/analysis/ratios'),
        statusCode: 500,
        data: {'error': 'boom'},
      ),
    ));

    final result = await repo.getRatios();

    expect(result.isLeft(), true);
    result.fold(
      (f) {
        expect(f, isA<ServerFailure>());
        expect(f.message, 'boom');
      },
      (_) => fail('expected Left'),
    );
  });

  test('getRatios returns Left(NetworkFailure) when offline', () async {
    when(() => net.isConnected).thenAnswer((_) async => false);
    final result = await repo.getRatios();
    expect(result.isLeft(), true);
    result.fold(
      (f) => expect(f, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });
}

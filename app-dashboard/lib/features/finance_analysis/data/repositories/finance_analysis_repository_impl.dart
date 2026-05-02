import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '../../domain/repositories/finance_analysis_repository.dart';
import '../datasources/finance_analysis_remote_datasource.dart';

class FinanceAnalysisRepositoryImpl implements FinanceAnalysisRepository {
  final FinanceAnalysisRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const FinanceAnalysisRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  String _extractError(DioException e, String fallback) {
    final msg = e.response?.data is Map
        ? (e.response!.data as Map)['error']?.toString() ?? e.message
        : e.message;
    return msg ?? fallback;
  }

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() body,
    String fallback,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await body());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, fallback)));
    }
  }

  @override
  Future<Either<Failure, FinancialRatiosEntity>> getRatios({
    String period = 'monthly',
    String? branchId,
    String comparison = 'prev_month',
  }) =>
      _guard(
        () async => (await remoteDataSource.fetchRatios(
          period: period,
          branchId: branchId,
          comparison: comparison,
        ))
            .toEntity(),
        'Gagal memuat rasio keuangan',
      );

  @override
  Future<Either<Failure, RevenueAnalysisEntity>> getRevenue({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) =>
      _guard(
        () async => (await remoteDataSource.fetchRevenue(
          period: period,
          branchId: branchId,
          groupBy: groupBy,
        ))
            .toEntity(),
        'Gagal memuat analisis pendapatan',
      );

  @override
  Future<Either<Failure, CostAnalysisEntity>> getCosts({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'category',
  }) =>
      _guard(
        () async => (await remoteDataSource.fetchCosts(
          period: period,
          branchId: branchId,
          groupBy: groupBy,
        ))
            .toEntity(),
        'Gagal memuat analisis biaya',
      );

  @override
  Future<Either<Failure, BatchProfitEntity>> getBatchProfit({
    String period = 'monthly',
    String? branchId,
    String sort = 'top',
    int limit = 10,
  }) =>
      _guard(
        () async => (await remoteDataSource.fetchBatchProfit(
          period: period,
          branchId: branchId,
          sort: sort,
          limit: limit,
        ))
            .toEntity(),
        'Gagal memuat profitabilitas batch',
      );

  @override
  Future<Either<Failure, CashForecastEntity>> getCashForecast({
    int months = 3,
    String? branchId,
  }) =>
      _guard(
        () async => (await remoteDataSource.fetchCashForecast(
          months: months,
          branchId: branchId,
        ))
            .toEntity(),
        'Gagal memuat proyeksi kas',
      );

  @override
  Future<Either<Failure, List<FinancialAlert>>> getAlerts() => _guard(
        () async => (await remoteDataSource.fetchAlerts())
            .map((e) => e.toEntity())
            .toList(),
        'Gagal memuat peringatan keuangan',
      );

  @override
  Future<Either<Failure, List<FinancialSuggestion>>> getSuggestions() => _guard(
        () async => (await remoteDataSource.fetchSuggestions())
            .map((e) => e.toEntity())
            .toList(),
        'Gagal memuat saran keuangan',
      );
}

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

  @override
  Future<Either<Failure, FinancialRatioEntity>> getRatios({
    String period = 'monthly',
    String? branchId,
    String comparison = 'vs_last_month',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.fetchRatios(
        period: period,
        branchId: branchId,
        comparison: comparison,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat rasio keuangan')));
    }
  }

  @override
  Future<Either<Failure, RevenueAnalysisEntity>> getRevenue({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.fetchRevenue(
        period: period,
        branchId: branchId,
        groupBy: groupBy,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat analisis pendapatan')));
    }
  }

  @override
  Future<Either<Failure, CostAnalysisEntity>> getCosts({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.fetchCosts(
        period: period,
        branchId: branchId,
        groupBy: groupBy,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat analisis biaya')));
    }
  }

  @override
  Future<Either<Failure, BatchProfitAnalysisEntity>> getBatchProfit({
    String period = 'monthly',
    String? branchId,
    int limit = 10,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.fetchBatchProfit(
        period: period,
        branchId: branchId,
        limit: limit,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat profitabilitas batch')));
    }
  }

  @override
  Future<Either<Failure, CashForecastEntity>> getCashForecast({
    int months = 3,
    String? branchId,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.fetchCashForecast(
        months: months,
        branchId: branchId,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat proyeksi kas')));
    }
  }

  @override
  Future<Either<Failure, List<FinanceAlertEntity>>> getAlerts() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.fetchAlerts();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat peringatan keuangan')));
    }
  }

  @override
  Future<Either<Failure, List<FinanceAlertEntity>>> getSuggestions() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.fetchSuggestions();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat rekomendasi keuangan')));
    }
  }
}

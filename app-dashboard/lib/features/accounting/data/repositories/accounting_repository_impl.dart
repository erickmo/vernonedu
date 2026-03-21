import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/accounting_stats_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/coa_entity.dart';
import '../../domain/entities/budget_item_entity.dart';
import '../../domain/repositories/accounting_repository.dart';
import '../datasources/accounting_remote_datasource.dart';

class AccountingRepositoryImpl implements AccountingRepository {
  final AccountingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const AccountingRepositoryImpl({
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
  Future<Either<Failure, AccountingStatsEntity>> getStats({
    required int month,
    required int year,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getStats(month: month, year: year);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat statistik akuntansi')));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? type,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getTransactions(
        offset: offset,
        limit: limit,
        month: month,
        year: year,
        type: type,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat transaksi')));
    }
  }

  @override
  Future<Either<Failure, void>> createTransaction({
    required Map<String, dynamic> body,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createTransaction(body: body);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat transaksi')));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? status,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getInvoices(
        offset: offset,
        limit: limit,
        month: month,
        year: year,
        status: status,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat faktur')));
    }
  }

  @override
  Future<Either<Failure, void>> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateInvoiceStatus(id: id, status: status);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah status faktur')));
    }
  }

  @override
  Future<Either<Failure, List<CoaEntity>>> getCoa() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getCoa();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat buku besar')));
    }
  }

  @override
  Future<Either<Failure, List<BudgetItemEntity>>> getBudgetVsActual({
    required int month,
    required int year,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getBudgetVsActual(
        month: month,
        year: year,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat anggaran vs realisasi')));
    }
  }
}

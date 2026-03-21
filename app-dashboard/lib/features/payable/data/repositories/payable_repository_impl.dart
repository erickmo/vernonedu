import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/payable_entity.dart';
import '../../domain/repositories/payable_repository.dart';
import '../datasources/payable_remote_datasource.dart';

class PayableRepositoryImpl implements PayableRepository {
  final PayableRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const PayableRepositoryImpl({
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
  Future<Either<Failure, PayableStatsEntity>> getPayableStats() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPayableStats();
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat statistik hutang')));
    }
  }

  @override
  Future<Either<Failure, List<PayableEntity>>> getPayables({
    int offset = 0,
    int limit = 20,
    String? type,
    String? status,
    String? batchId,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPayables(
        offset: offset,
        limit: limit,
        type: type,
        status: status,
        batchId: batchId,
      );
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat daftar hutang')));
    }
  }

  @override
  Future<Either<Failure, PayableEntity>> getPayableById(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPayableById(id);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat detail hutang')));
    }
  }

  @override
  Future<Either<Failure, void>> markPayableAsPaid(
    String id, {
    String? paymentProof,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.markPayableAsPaid(id, paymentProof: paymentProof);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menandai hutang sebagai dibayar')));
    }
  }
}

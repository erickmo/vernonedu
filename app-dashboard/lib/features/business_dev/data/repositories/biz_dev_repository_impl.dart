import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/okr_entity.dart';
import '../../domain/repositories/biz_dev_repository.dart';
import '../datasources/biz_dev_remote_datasource.dart';

class BizDevRepositoryImpl implements BizDevRepository {
  final BizDevRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const BizDevRepositoryImpl({
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
  Future<Either<Failure, Map<String, dynamic>>> getPartners({
    int offset = 0,
    int limit = 20,
    String status = '',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPartners(
        offset: offset,
        limit: limit,
        status: status,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat data partner')));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBranches({
    int offset = 0,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getBranches(
        offset: offset,
        limit: limit,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat data cabang')));
    }
  }

  @override
  Future<Either<Failure, List<OkrObjectiveEntity>>> getOkrObjectives({
    String level = '',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result =
          await remoteDataSource.getOkrObjectives(level: level);
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat data OKR')));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getInvestments({
    int offset = 0,
    int limit = 20,
    String status = '',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getInvestments(
        offset: offset,
        limit: limit,
        status: status,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(
          ServerFailure(_extractError(e, 'Gagal memuat rencana investasi')));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDelegations({
    int offset = 0,
    int limit = 20,
    String status = '',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getDelegations(
        offset: offset,
        limit: limit,
        status: status,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat delegasi')));
    }
  }
}

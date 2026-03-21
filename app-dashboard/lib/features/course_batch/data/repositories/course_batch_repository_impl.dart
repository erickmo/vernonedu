import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_batch_detail_entity.dart';
import '../../domain/entities/course_batch_entity.dart';
import '../../domain/repositories/course_batch_repository.dart';
import '../datasources/course_batch_remote_datasource.dart';

class CourseBatchRepositoryImpl implements CourseBatchRepository {
  final CourseBatchRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const CourseBatchRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CourseBatchEntity>>> getCourseBatches({int offset = 0, int limit = 20}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getCourseBatches(offset: offset, limit: limit);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, CourseBatchDetailEntity>> getCourseBatchDetail(String batchId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getCourseBatchDetail(batchId);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, void>> createCourseBatch(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createCourseBatch(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }
}

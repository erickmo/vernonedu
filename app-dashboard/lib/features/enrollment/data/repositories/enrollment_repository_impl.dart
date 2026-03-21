import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/enrollment_batch_summary_entity.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../datasources/enrollment_remote_datasource.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final EnrollmentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const EnrollmentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollments({int offset = 0, int limit = 20}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getEnrollments(offset: offset, limit: limit);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, List<EnrollmentBatchSummaryEntity>>> getEnrollmentSummary() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getEnrollmentSummary();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, void>> enrollStudent(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.enrollStudent(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEnrollmentStatus(String id, String status) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateEnrollmentStatus(id, status);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengubah status enrollment'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEnrollmentPaymentStatus(String id, String paymentStatus) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateEnrollmentPaymentStatus(id, paymentStatus);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengubah status pembayaran'));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_module_entity.dart';
import '../../domain/repositories/course_module_repository.dart';
import '../datasources/course_module_remote_datasource.dart';

// Implementasi repository CourseModule — menangani DioException sesuai pola existing
class CourseModuleRepositoryImpl implements CourseModuleRepository {
  final CourseModuleRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const CourseModuleRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CourseModuleEntity>>> getModulesByVersion(String versionId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getModulesByVersion(versionId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat daftar modul'));
    }
  }

  @override
  Future<Either<Failure, void>> createModule(String versionId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createModule(versionId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal membuat modul'));
    }
  }

  @override
  Future<Either<Failure, void>> updateModule(String moduleId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateModule(moduleId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengupdate modul'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteModule(String moduleId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteModule(moduleId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal menghapus modul'));
    }
  }
}

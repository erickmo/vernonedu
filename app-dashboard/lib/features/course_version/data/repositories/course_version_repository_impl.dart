import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_version_entity.dart';
import '../../domain/entities/internship_config_entity.dart';
import '../../domain/entities/character_test_config_entity.dart';
import '../../domain/repositories/course_version_repository.dart';
import '../datasources/course_version_remote_datasource.dart';

// Implementasi repository CourseVersion — menangani DioException sesuai pola existing
class CourseVersionRepositoryImpl implements CourseVersionRepository {
  final CourseVersionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const CourseVersionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CourseVersionEntity>>> getVersionsByType(String typeId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getVersionsByType(typeId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat daftar versi'));
    }
  }

  @override
  Future<Either<Failure, CourseVersionEntity>> getVersionById(String versionId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getVersionById(versionId);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat detail versi'));
    }
  }

  @override
  Future<Either<Failure, void>> createVersion(String typeId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createVersion(typeId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal membuat versi baru'));
    }
  }

  @override
  Future<Either<Failure, void>> promoteVersion(String versionId, String targetStatus) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.promoteVersion(versionId, targetStatus);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mempromosikan versi'));
    }
  }

  @override
  Future<Either<Failure, InternshipConfigEntity?>> getInternshipConfig(String versionId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getInternshipConfig(versionId);
      return Right(result?.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat konfigurasi magang'));
    }
  }

  @override
  Future<Either<Failure, void>> upsertInternshipConfig(String versionId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.upsertInternshipConfig(versionId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal menyimpan konfigurasi magang'));
    }
  }

  @override
  Future<Either<Failure, CharacterTestConfigEntity?>> getCharacterTestConfig(String versionId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getCharacterTestConfig(versionId);
      return Right(result?.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat konfigurasi tes karakter'));
    }
  }

  @override
  Future<Either<Failure, void>> upsertCharacterTestConfig(String versionId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.upsertCharacterTestConfig(versionId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal menyimpan konfigurasi tes karakter'));
    }
  }
}

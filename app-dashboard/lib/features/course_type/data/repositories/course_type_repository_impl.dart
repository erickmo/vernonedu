import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_type_entity.dart';
import '../../domain/repositories/course_type_repository.dart';
import '../datasources/course_type_remote_datasource.dart';

// Implementasi repository CourseType — menangani DioException sesuai pola existing
class CourseTypeRepositoryImpl implements CourseTypeRepository {
  final CourseTypeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const CourseTypeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CourseTypeEntity>>> getTypesByCourse(String courseId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getTypesByCourse(courseId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat tipe course'));
    }
  }

  @override
  Future<Either<Failure, CourseTypeEntity>> getTypeById(String typeId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getTypeById(typeId);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat detail tipe'));
    }
  }

  @override
  Future<Either<Failure, void>> createType(String courseId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createType(courseId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal membuat tipe course'));
    }
  }

  @override
  Future<Either<Failure, void>> updateType(String typeId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateType(typeId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengupdate tipe course'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleType(String typeId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.toggleType(typeId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengubah status tipe'));
    }
  }
}

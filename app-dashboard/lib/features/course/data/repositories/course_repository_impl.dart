import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

// Implementasi repository MasterCourse — handle network check & error mapping
class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const CourseRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CourseEntity>>> getCourses({
    int offset = 0,
    int limit = 20,
    String status = '',
    String field = '',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getCourses(
        offset: offset,
        limit: limit,
        status: status,
        field: field,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat daftar course'));
    }
  }

  @override
  Future<Either<Failure, CourseEntity>> getCourseById(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getCourseById(id);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat detail course'));
    }
  }

  @override
  Future<Either<Failure, void>> createCourse(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createCourse(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal membuat course'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCourse(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateCourse(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengupdate course'));
    }
  }

  @override
  Future<Either<Failure, void>> archiveCourse(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.archiveCourse(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengarsipkan course'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCourse(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteCourse(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal menghapus course'));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/department_summary_entity.dart';
import '../../domain/entities/department_batch_entity.dart';
import '../../domain/entities/department_course_entity.dart';
import '../../domain/entities/department_student_entity.dart';
import '../../domain/entities/department_talentpool_entity.dart';
import '../../domain/repositories/department_repository.dart';
import '../datasources/department_remote_datasource.dart';

class DepartmentRepositoryImpl implements DepartmentRepository {
  final DepartmentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const DepartmentRepositoryImpl({
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
  Future<Either<Failure, List<DepartmentEntity>>> getDepartments({int offset = 0, int limit = 100}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getDepartments(offset: offset, limit: limit);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Terjadi kesalahan')));
    }
  }

  @override
  Future<Either<Failure, void>> createDepartment(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createDepartment(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat departemen')));
    }
  }

  @override
  Future<Either<Failure, void>> updateDepartment(String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateDepartment(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah departemen')));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDepartment(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteDepartment(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus departemen')));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentSummaryEntity>>> getDepartmentSummaries() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getDepartmentSummaries();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat ringkasan departemen')));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentBatchEntity>>> getDepartmentBatches(String departmentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getDepartmentBatches(departmentId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat batch departemen')));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentCourseEntity>>> getDepartmentCourses(String departmentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getDepartmentCourses(departmentId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat kursus departemen')));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentStudentEntity>>> getDepartmentStudents(String departmentId, {String status = ''}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getDepartmentStudents(departmentId, status: status);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat siswa departemen')));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentTalentPoolEntity>>> getDepartmentTalentPool(String departmentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getDepartmentTalentPool(departmentId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat talent pool departemen')));
    }
  }

  @override
  Future<Either<Failure, void>> assignBatchFacilitator(String batchId, String facilitatorId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.assignBatchFacilitator(batchId, facilitatorId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal assign fasilitator')));
    }
  }
}

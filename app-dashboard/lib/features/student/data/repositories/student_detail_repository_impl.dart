import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/student_detail_entity.dart';
import '../../domain/entities/student_enrollment_history_entity.dart';
import '../../domain/entities/student_note_entity.dart';
import '../../domain/entities/recommended_course_entity.dart';
import '../../domain/entities/student_crm_log_entity.dart';
import '../../domain/repositories/student_detail_repository.dart';
import '../datasources/student_detail_remote_datasource.dart';

class StudentDetailRepositoryImpl implements StudentDetailRepository {
  final StudentDetailRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const StudentDetailRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, StudentDetailEntity>> getStudentDetail(
      String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getStudentDetail(id);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat data siswa'));
    }
  }

  @override
  Future<Either<Failure, List<StudentEnrollmentHistoryEntity>>>
      getStudentEnrollmentHistory(String studentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result =
          await remoteDataSource.getStudentEnrollmentHistory(studentId);
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat riwayat enrollment'));
    }
  }

  @override
  Future<Either<Failure, List<RecommendedCourseEntity>>>
      getStudentRecommendations(String studentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result =
          await remoteDataSource.getStudentRecommendations(studentId);
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.message ?? 'Gagal memuat rekomendasi course'));
    }
  }

  @override
  Future<Either<Failure, List<StudentNoteEntity>>> getStudentNotes(
      String studentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getStudentNotes(studentId);
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat catatan'));
    }
  }

  @override
  Future<Either<Failure, StudentNoteEntity>> addStudentNote(
      String studentId, String content) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.addStudentNote(studentId, content);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal menambah catatan'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStudent(
    String id, {
    required String name,
    required String email,
    required String phone,
    String? nik,
    String? gender,
    String? address,
    String? birthDate,
    String? departmentId,
    required String status,
    String? studentCode,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateStudent(
        id,
        name: name,
        email: email,
        phone: phone,
        nik: nik,
        gender: gender,
        address: address,
        birthDate: birthDate,
        departmentId: departmentId,
        status: status,
        studentCode: studentCode,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengupdate data siswa'));
    }
  }

  @override
  Future<Either<Failure, List<StudentCrmLogEntity>>> getStudentCrmLogs(
      String studentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getStudentCrmLogs(studentId);
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat log CRM'));
    }
  }

  @override
  Future<Either<Failure, StudentCrmLogEntity>> addStudentCrmLog(
    String studentId, {
    required String contactMethod,
    required String response,
    String? contactedBy,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.addStudentCrmLog(
        studentId,
        contactMethod: contactMethod,
        response: response,
        contactedBy: contactedBy,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal menambah log CRM'));
    }
  }
}

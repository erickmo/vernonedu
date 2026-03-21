import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_record_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _remote;

  const AttendanceRepositoryImpl({required AttendanceRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Either<Failure, List<AttendanceSessionEntity>>> getSessions(
      String batchId) async {
    try {
      final models = await _remote.getSessions(batchId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal memuat sesi';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal memuat sesi'));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRecordEntity>>> getAttendanceRecords(
      String batchId, String sessionId) async {
    try {
      final models = await _remote.getAttendanceRecords(batchId, sessionId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal memuat absensi';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal memuat absensi'));
    }
  }

  @override
  Future<Either<Failure, void>> submitAttendance(
    String batchId,
    String sessionId,
    List<AttendanceRecordEntity> records,
  ) async {
    try {
      final models = records
          .map((r) => AttendanceRecordModel(
                studentId: r.studentId,
                studentName: r.studentName,
                studentCode: r.studentCode,
                status: r.status,
                note: r.note,
              ))
          .toList();
      await _remote.submitAttendance(batchId, sessionId, models);
      return const Right(null);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal menyimpan absensi';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal menyimpan absensi'));
    }
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/attendance_record_entity.dart';
import '../entities/attendance_session_entity.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, List<AttendanceSessionEntity>>> getSessions(
      String batchId);
  Future<Either<Failure, List<AttendanceRecordEntity>>> getAttendanceRecords(
      String batchId, String sessionId);
  Future<Either<Failure, void>> submitAttendance(
    String batchId,
    String sessionId,
    List<AttendanceRecordEntity> records,
  );
}

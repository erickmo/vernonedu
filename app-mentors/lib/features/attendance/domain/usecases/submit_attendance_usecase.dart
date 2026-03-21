import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/attendance_record_entity.dart';
import '../repositories/attendance_repository.dart';

class SubmitAttendanceUseCase {
  final AttendanceRepository _repository;

  const SubmitAttendanceUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String batchId,
    String sessionId,
    List<AttendanceRecordEntity> records,
  ) =>
      _repository.submitAttendance(batchId, sessionId, records);
}

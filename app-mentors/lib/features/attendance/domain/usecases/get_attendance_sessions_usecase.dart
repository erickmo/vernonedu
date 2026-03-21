import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/attendance_session_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceSessionsUseCase {
  final AttendanceRepository _repository;

  const GetAttendanceSessionsUseCase(this._repository);

  Future<Either<Failure, List<AttendanceSessionEntity>>> call(
          String batchId) =>
      _repository.getSessions(batchId);
}

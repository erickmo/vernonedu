import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/schedule_session_entity.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleSessionEntity>>> getMySchedule({
    required DateTime from,
    required DateTime to,
  });
}

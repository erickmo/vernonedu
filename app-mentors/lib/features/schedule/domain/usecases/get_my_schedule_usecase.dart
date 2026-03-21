import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/schedule_session_entity.dart';
import '../repositories/schedule_repository.dart';

class GetMyScheduleUseCase {
  final ScheduleRepository _repository;

  const GetMyScheduleUseCase(this._repository);

  Future<Either<Failure, List<ScheduleSessionEntity>>> call({
    required DateTime from,
    required DateTime to,
  }) =>
      _repository.getMySchedule(from: from, to: to);
}

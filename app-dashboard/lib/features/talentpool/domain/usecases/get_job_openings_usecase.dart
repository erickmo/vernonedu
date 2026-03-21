import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/job_opening_entity.dart';
import '../repositories/talentpool_repository.dart';

class GetJobOpeningsUseCase {
  final TalentPoolRepository _repository;
  const GetJobOpeningsUseCase(this._repository);

  Future<Either<Failure, List<JobOpeningEntity>>> call() =>
      _repository.getJobOpenings();
}

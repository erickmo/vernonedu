import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/facilitator_entity.dart';
import '../repositories/assignment_repository.dart';

class GetFacilitatorsUseCase {
  final AssignmentRepository _repository;

  const GetFacilitatorsUseCase(this._repository);

  Future<Either<Failure, List<FacilitatorEntity>>> call() =>
      _repository.getFacilitators();
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/batch_repository.dart';

class AssignFacilitatorUseCase {
  final BatchRepository _repository;

  const AssignFacilitatorUseCase(this._repository);

  Future<Either<Failure, void>> call(String batchId, String facilitatorId) =>
      _repository.assignFacilitator(batchId, facilitatorId);
}

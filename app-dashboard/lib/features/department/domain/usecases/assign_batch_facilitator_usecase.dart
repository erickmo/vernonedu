import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/department_repository.dart';

class AssignBatchFacilitatorUseCase {
  final DepartmentRepository repository;
  const AssignBatchFacilitatorUseCase(this.repository);

  Future<Either<Failure, void>> call(String batchId, String facilitatorId) =>
      repository.assignBatchFacilitator(batchId, facilitatorId);
}

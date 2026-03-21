import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_batch_entity.dart';
import '../repositories/department_repository.dart';

class GetDepartmentBatchesUseCase {
  final DepartmentRepository repository;
  const GetDepartmentBatchesUseCase(this.repository);

  Future<Either<Failure, List<DepartmentBatchEntity>>> call(String departmentId) =>
      repository.getDepartmentBatches(departmentId);
}

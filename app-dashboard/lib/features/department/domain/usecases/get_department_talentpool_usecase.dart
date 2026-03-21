import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_talentpool_entity.dart';
import '../repositories/department_repository.dart';

class GetDepartmentTalentPoolUseCase {
  final DepartmentRepository repository;
  const GetDepartmentTalentPoolUseCase(this.repository);

  Future<Either<Failure, List<DepartmentTalentPoolEntity>>> call(String departmentId) =>
      repository.getDepartmentTalentPool(departmentId);
}

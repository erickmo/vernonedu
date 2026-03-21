import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/department_repository.dart';

class UpdateDepartmentUseCase {
  final DepartmentRepository repository;
  const UpdateDepartmentUseCase(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> data) =>
      repository.updateDepartment(id, data);
}

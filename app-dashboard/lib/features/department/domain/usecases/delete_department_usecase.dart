import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/department_repository.dart';

class DeleteDepartmentUseCase {
  final DepartmentRepository repository;
  const DeleteDepartmentUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.deleteDepartment(id);
}

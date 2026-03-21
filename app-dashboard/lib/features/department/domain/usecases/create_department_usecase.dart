import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/department_repository.dart';

class CreateDepartmentUseCase {
  final DepartmentRepository repository;
  const CreateDepartmentUseCase(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      repository.createDepartment(data);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_entity.dart';
import '../repositories/department_repository.dart';

class GetDepartmentsUseCase {
  final DepartmentRepository _repository;
  const GetDepartmentsUseCase(this._repository);
  Future<Either<Failure, List<DepartmentEntity>>> call({int offset = 0, int limit = 20}) =>
      _repository.getDepartments(offset: offset, limit: limit);
}

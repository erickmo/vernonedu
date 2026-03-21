import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_summary_entity.dart';
import '../repositories/department_repository.dart';

class GetDepartmentSummaryUseCase {
  final DepartmentRepository repository;
  const GetDepartmentSummaryUseCase(this.repository);

  Future<Either<Failure, List<DepartmentSummaryEntity>>> call() =>
      repository.getDepartmentSummaries();
}

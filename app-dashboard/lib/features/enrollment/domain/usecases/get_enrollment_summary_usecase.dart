import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/enrollment_batch_summary_entity.dart';
import '../repositories/enrollment_repository.dart';

class GetEnrollmentSummaryUseCase {
  final EnrollmentRepository repository;
  const GetEnrollmentSummaryUseCase(this.repository);

  Future<Either<Failure, List<EnrollmentBatchSummaryEntity>>> call() {
    return repository.getEnrollmentSummary();
  }
}

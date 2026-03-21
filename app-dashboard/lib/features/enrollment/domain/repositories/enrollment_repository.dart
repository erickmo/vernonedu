import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/enrollment_batch_summary_entity.dart';
import '../entities/enrollment_entity.dart';

abstract class EnrollmentRepository {
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollments({int offset = 0, int limit = 20});
  Future<Either<Failure, List<EnrollmentBatchSummaryEntity>>> getEnrollmentSummary();
  Future<Either<Failure, void>> enrollStudent(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateEnrollmentStatus(String id, String status);
  Future<Either<Failure, void>> updateEnrollmentPaymentStatus(String id, String paymentStatus);
}

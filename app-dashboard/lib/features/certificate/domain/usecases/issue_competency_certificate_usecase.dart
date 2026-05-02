import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/certificate_repository.dart';

/// Issues a competency certificate. Backend mandates `testPassed=true`.
class IssueCompetencyCertificateUseCase {
  final CertificateRepository _repository;
  const IssueCompetencyCertificateUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String studentId,
    required String courseId,
    String? batchId,
    String? templateId,
    bool testPassed = true,
    String? verificationBaseUrl,
  }) =>
      _repository.issueCompetency(
        studentId: studentId,
        courseId: courseId,
        batchId: batchId,
        templateId: templateId,
        testPassed: testPassed,
        verificationBaseUrl: verificationBaseUrl,
      );
}

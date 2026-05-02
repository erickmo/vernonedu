import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/certificate_repository.dart';

/// Issues participant certificates for one or many students in a batch.
/// Internally fans out to the single-student endpoint.
class IssueParticipantCertificateUseCase {
  final CertificateRepository _repository;
  const IssueParticipantCertificateUseCase(this._repository);

  Future<Either<Failure, int>> call({
    required String batchId,
    required List<String> studentIds,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  }) =>
      _repository.issueParticipantBulk(
        batchId: batchId,
        studentIds: studentIds,
        courseId: courseId,
        templateId: templateId,
        verificationBaseUrl: verificationBaseUrl,
      );
}

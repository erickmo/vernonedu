import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/certificate_entity.dart';
import '../repositories/certificate_repository.dart';

class GetCertificatesUseCase {
  final CertificateRepository _repository;
  const GetCertificatesUseCase(this._repository);

  Future<Either<Failure, List<CertificateEntity>>> call({
    String? studentId,
    String? batchId,
    String? type,
    String? status,
    int offset = 0,
    int limit = 50,
  }) =>
      _repository.getCertificates(
        studentId: studentId,
        batchId: batchId,
        type: type,
        status: status,
        offset: offset,
        limit: limit,
      );
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/certificate_entity.dart';
import '../repositories/certificate_repository.dart';

class ListCertificatesByBatchUseCase {
  final CertificateRepository _repository;
  const ListCertificatesByBatchUseCase(this._repository);

  Future<Either<Failure, List<CertificateEntity>>> call(String batchId) =>
      _repository.listByBatch(batchId);
}

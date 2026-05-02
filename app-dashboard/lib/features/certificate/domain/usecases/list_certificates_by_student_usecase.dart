import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/certificate_entity.dart';
import '../repositories/certificate_repository.dart';

class ListCertificatesByStudentUseCase {
  final CertificateRepository _repository;
  const ListCertificatesByStudentUseCase(this._repository);

  Future<Either<Failure, List<CertificateEntity>>> call(String studentId) =>
      _repository.listByStudent(studentId);
}

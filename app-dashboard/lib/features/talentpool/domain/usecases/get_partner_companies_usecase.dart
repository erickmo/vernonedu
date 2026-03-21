import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/partner_company_entity.dart';
import '../repositories/talentpool_repository.dart';

class GetPartnerCompaniesUseCase {
  final TalentPoolRepository _repository;
  const GetPartnerCompaniesUseCase(this._repository);

  Future<Either<Failure, List<PartnerCompanyEntity>>> call() =>
      _repository.getPartnerCompanies();
}

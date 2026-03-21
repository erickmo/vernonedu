import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/referral_partner_entity.dart';
import '../repositories/marketing_repository.dart';

class GetReferralPartnersUseCase {
  final MarketingRepository _repository;
  const GetReferralPartnersUseCase(this._repository);

  Future<Either<Failure, List<ReferralPartnerEntity>>> call() =>
      _repository.getReferralPartners();
}

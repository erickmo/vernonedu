import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/referral_entity.dart';
import '../repositories/marketing_repository.dart';

class GetReferralsUseCase {
  final MarketingRepository _repository;
  const GetReferralsUseCase(this._repository);

  Future<Either<Failure, List<ReferralEntity>>> call(String partnerId) =>
      _repository.getReferrals(partnerId);
}

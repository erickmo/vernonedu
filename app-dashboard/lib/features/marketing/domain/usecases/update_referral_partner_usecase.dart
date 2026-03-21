import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class UpdateReferralPartnerUseCase {
  final MarketingRepository _repository;
  const UpdateReferralPartnerUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> data) =>
      _repository.updateReferralPartner(id, data);
}

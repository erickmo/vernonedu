import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class CreateReferralPartnerUseCase {
  final MarketingRepository _repository;
  const CreateReferralPartnerUseCase(this._repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createReferralPartner(data);
}

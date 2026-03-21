import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/partner_detail_repository.dart';

class GetPartnerDetailUseCase {
  final PartnerDetailRepository _repository;
  const GetPartnerDetailUseCase(this._repository);

  Future<Either<Failure, PartnerDetailData>> call(String partnerId) =>
      _repository.getPartnerDetail(partnerId);
}

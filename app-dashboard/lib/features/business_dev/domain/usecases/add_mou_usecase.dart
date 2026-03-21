import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/partner_detail_repository.dart';

class AddMouUseCase {
  final PartnerDetailRepository _repository;
  const AddMouUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String partnerId,
    Map<String, dynamic> body,
  ) =>
      _repository.addMOU(partnerId, body);
}

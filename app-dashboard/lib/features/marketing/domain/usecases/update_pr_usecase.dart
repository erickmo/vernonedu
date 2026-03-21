import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class UpdatePrUseCase {
  final MarketingRepository _repository;
  const UpdatePrUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> data) =>
      _repository.updatePr(id, data);
}

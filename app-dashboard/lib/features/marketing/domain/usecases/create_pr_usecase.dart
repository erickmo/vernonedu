import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class CreatePrUseCase {
  final MarketingRepository _repository;
  const CreatePrUseCase(this._repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createPr(data);
}

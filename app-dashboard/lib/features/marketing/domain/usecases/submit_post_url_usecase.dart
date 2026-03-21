import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class SubmitPostUrlUseCase {
  final MarketingRepository _repository;
  const SubmitPostUrlUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, String url) =>
      _repository.submitPostUrl(id, url);
}

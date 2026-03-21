import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class CreatePostUseCase {
  final MarketingRepository _repository;
  const CreatePostUseCase(this._repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createPost(data);
}

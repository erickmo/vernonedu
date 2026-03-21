import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class CreateCmsFaqUseCase {
  final CmsRepository _repository;
  const CreateCmsFaqUseCase(this._repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createFaq(data);
}

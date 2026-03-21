import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class UpdateCmsFaqUseCase {
  final CmsRepository _repository;
  const UpdateCmsFaqUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> data) =>
      _repository.updateFaq(id, data);
}

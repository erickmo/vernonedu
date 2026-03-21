import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/biz_dev_repository.dart';

class GetBranchesUseCase {
  final BizDevRepository _repository;
  const GetBranchesUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    int offset = 0,
    int limit = 20,
  }) =>
      _repository.getBranches(offset: offset, limit: limit);
}

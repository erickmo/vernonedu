import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/biz_dev_repository.dart';

class GetDelegationsUseCase {
  final BizDevRepository _repository;
  const GetDelegationsUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    int offset = 0,
    int limit = 20,
    String status = '',
  }) =>
      _repository.getDelegations(offset: offset, limit: limit, status: status);
}

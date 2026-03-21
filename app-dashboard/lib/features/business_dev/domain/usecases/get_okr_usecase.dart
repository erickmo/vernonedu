import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/okr_entity.dart';
import '../repositories/biz_dev_repository.dart';

class GetOkrUseCase {
  final BizDevRepository _repository;
  const GetOkrUseCase(this._repository);

  Future<Either<Failure, List<OkrObjectiveEntity>>> call({
    String level = '',
  }) =>
      _repository.getOkrObjectives(level: level);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pr_schedule_entity.dart';
import '../repositories/marketing_repository.dart';

class GetPrUseCase {
  final MarketingRepository _repository;
  const GetPrUseCase(this._repository);

  Future<Either<Failure, List<PrScheduleEntity>>> call({
    String? status,
    String? type,
  }) =>
      _repository.getPr(status: status, type: type);
}

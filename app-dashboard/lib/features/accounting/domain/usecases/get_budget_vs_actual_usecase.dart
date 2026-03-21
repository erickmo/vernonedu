import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/budget_item_entity.dart';
import '../repositories/accounting_repository.dart';

class GetBudgetVsActualUseCase {
  final AccountingRepository _repository;
  const GetBudgetVsActualUseCase(this._repository);

  Future<Either<Failure, List<BudgetItemEntity>>> call({
    required int month,
    required int year,
  }) =>
      _repository.getBudgetVsActual(month: month, year: year);
}

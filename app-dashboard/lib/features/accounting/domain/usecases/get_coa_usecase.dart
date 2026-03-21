import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/coa_entity.dart';
import '../repositories/accounting_repository.dart';

class GetCoaUseCase {
  final AccountingRepository _repository;
  const GetCoaUseCase(this._repository);

  Future<Either<Failure, List<CoaEntity>>> call() =>
      _repository.getCoa();
}

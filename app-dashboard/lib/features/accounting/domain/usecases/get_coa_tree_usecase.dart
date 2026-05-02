import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/coa_tree_node_entity.dart';
import '../repositories/accounting_repository.dart';

class GetCoaTreeUseCase {
  final AccountingRepository _repository;
  const GetCoaTreeUseCase(this._repository);

  Future<Either<Failure, List<CoaTreeNodeEntity>>> call() =>
      _repository.getCoaTree();
}

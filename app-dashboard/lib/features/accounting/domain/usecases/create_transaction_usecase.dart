import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/accounting_repository.dart';

class CreateTransactionUseCase {
  final AccountingRepository _repository;
  const CreateTransactionUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required Map<String, dynamic> body,
  }) =>
      _repository.createTransaction(body: body);
}

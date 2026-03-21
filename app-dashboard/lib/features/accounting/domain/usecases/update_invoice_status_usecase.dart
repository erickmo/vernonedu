import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/accounting_repository.dart';

class UpdateInvoiceStatusUseCase {
  final AccountingRepository _repository;
  const UpdateInvoiceStatusUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String id,
    required String status,
  }) =>
      _repository.updateInvoiceStatus(id: id, status: status);
}

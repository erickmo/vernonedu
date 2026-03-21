import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/invoice_repository.dart';

class CancelInvoiceUseCase {
  final InvoiceRepository _repository;
  const CancelInvoiceUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String id,
    required String reason,
  }) =>
      _repository.cancelInvoice(id: id, reason: reason);
}

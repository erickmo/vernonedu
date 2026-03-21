import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/invoice_repository.dart';

class ResendInvoiceUseCase {
  final InvoiceRepository _repository;
  const ResendInvoiceUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.resendInvoice(id);
}

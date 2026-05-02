import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/invoice_repository.dart';

class SendInvoiceUseCase {
  final InvoiceRepository _repository;
  const SendInvoiceUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.sendInvoice(id);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/invoice_repository.dart';

class CreateManualInvoiceUseCase {
  final InvoiceRepository _repository;
  const CreateManualInvoiceUseCase(this._repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> body) =>
      _repository.createManualInvoice(body);
}

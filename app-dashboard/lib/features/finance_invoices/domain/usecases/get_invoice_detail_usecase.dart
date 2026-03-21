import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice_detail_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceDetailUseCase {
  final InvoiceRepository _repository;
  const GetInvoiceDetailUseCase(this._repository);

  Future<Either<Failure, InvoiceDetailEntity>> call(String id) =>
      _repository.getInvoiceDetail(id);
}

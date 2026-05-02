import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/entities/invoice_detail_entity.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/repositories/invoice_repository.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/cancel_invoice_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/get_invoice_detail_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/mark_invoice_paid_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/send_invoice_usecase.dart';

class _MockRepo extends Mock implements InvoiceRepository {}

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  test('SendInvoiceUseCase delegates to repo.sendInvoice', () async {
    when(() => repo.sendInvoice(any()))
        .thenAnswer((_) async => const Right(null));
    final uc = SendInvoiceUseCase(repo);
    final result = await uc('inv-1');
    expect(result.isRight(), true);
    verify(() => repo.sendInvoice('inv-1')).called(1);
  });

  test('CancelInvoiceUseCase delegates to repo.cancelInvoice', () async {
    when(() => repo.cancelInvoice(
          id: any(named: 'id'),
          reason: any(named: 'reason'),
        )).thenAnswer((_) async => const Right(null));
    final uc = CancelInvoiceUseCase(repo);
    final result = await uc(id: 'inv-1', reason: 'r');
    expect(result.isRight(), true);
    verify(() => repo.cancelInvoice(id: 'inv-1', reason: 'r')).called(1);
  });

  test('MarkInvoicePaidUseCase delegates with full args', () async {
    when(() => repo.markAsPaid(
          id: any(named: 'id'),
          paidAt: any(named: 'paidAt'),
          paidAmount: any(named: 'paidAmount'),
          paymentProof: any(named: 'paymentProof'),
          accountCode: any(named: 'accountCode'),
        )).thenAnswer((_) async => const Right(null));
    final uc = MarkInvoicePaidUseCase(repo);
    final result = await uc(
      id: 'inv-1',
      paidAt: '2026-05-03',
      paidAmount: 100,
      paymentProof: 'p',
      accountCode: '1101',
    );
    expect(result.isRight(), true);
  });

  test('GetInvoiceDetailUseCase delegates to repo.getInvoiceDetail', () async {
    final entity = InvoiceDetailEntity(
      id: 'inv-1',
      invoiceNumber: 'INV-1',
      studentName: 'A',
      studentContact: '0',
      batchCode: 'B',
      batchName: 'Batch',
      courseTypeName: 'Reg',
      paymentMethod: 'upfront',
      amount: 100,
      createdAt: DateTime(2026, 5, 1),
      dueDate: DateTime(2026, 6, 1),
      status: 'sent',
      source: 'auto',
      paymentHistory: const [],
    );
    when(() => repo.getInvoiceDetail(any()))
        .thenAnswer((_) async => Right(entity));
    final uc = GetInvoiceDetailUseCase(repo);
    final result = await uc('inv-1');
    expect(result.isRight(), true);
    verify(() => repo.getInvoiceDetail('inv-1')).called(1);
  });
}

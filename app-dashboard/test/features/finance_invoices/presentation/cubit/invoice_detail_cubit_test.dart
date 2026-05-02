import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/entities/invoice_detail_entity.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/repositories/invoice_repository.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/cancel_invoice_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/get_invoice_detail_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/mark_invoice_paid_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/domain/usecases/send_invoice_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/presentation/cubit/invoice_detail_cubit.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/presentation/cubit/invoice_detail_state.dart';

class _MockRepo extends Mock implements InvoiceRepository {}

InvoiceDetailEntity _entity({String status = 'sent'}) => InvoiceDetailEntity(
      id: 'inv-1',
      invoiceNumber: 'INV-1',
      studentName: 'Budi',
      studentContact: '081',
      batchCode: 'B',
      batchName: 'Batch',
      courseTypeName: 'Reg',
      paymentMethod: 'upfront',
      amount: 100000,
      createdAt: DateTime(2026, 5, 1),
      dueDate: DateTime(2026, 6, 1),
      status: status,
      source: 'auto',
      paymentHistory: const [],
    );

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  InvoiceDetailCubit build() => InvoiceDetailCubit(
        getDetail: GetInvoiceDetailUseCase(repo),
        markPaid: MarkInvoicePaidUseCase(repo),
        send: SendInvoiceUseCase(repo),
        cancel: CancelInvoiceUseCase(repo),
      );

  blocTest<InvoiceDetailCubit, InvoiceDetailState>(
    'load emits Loading then Loaded on success',
    build: () {
      when(() => repo.getInvoiceDetail(any()))
          .thenAnswer((_) async => Right(_entity()));
      return build();
    },
    act: (c) => c.load('inv-1'),
    expect: () => [
      isA<InvoiceDetailLoading>(),
      isA<InvoiceDetailLoaded>(),
    ],
  );

  blocTest<InvoiceDetailCubit, InvoiceDetailState>(
    'load emits Loading then Error on failure',
    build: () {
      when(() => repo.getInvoiceDetail(any()))
          .thenAnswer((_) async => const Left(ServerFailure('boom')));
      return build();
    },
    act: (c) => c.load('inv-1'),
    expect: () => [
      isA<InvoiceDetailLoading>(),
      isA<InvoiceDetailError>(),
    ],
  );

  blocTest<InvoiceDetailCubit, InvoiceDetailState>(
    'pay reloads detail with action message on success',
    build: () {
      when(() => repo.getInvoiceDetail(any()))
          .thenAnswer((_) async => Right(_entity(status: 'paid')));
      when(() => repo.markAsPaid(
            id: any(named: 'id'),
            paidAt: any(named: 'paidAt'),
            paidAmount: any(named: 'paidAmount'),
            paymentProof: any(named: 'paymentProof'),
            accountCode: any(named: 'accountCode'),
          )).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (c) async {
      await c.load('inv-1');
      await c.pay(paidAt: '2026-05-03', paidAmount: 100000);
    },
    skip: 2,
    expect: () => [
      predicate<InvoiceDetailLoaded>(
          (s) => s.actionMessage == 'Invoice berhasil ditandai lunas'),
    ],
  );

  blocTest<InvoiceDetailCubit, InvoiceDetailState>(
    'cancelInvoice reloads with cancel message',
    build: () {
      when(() => repo.getInvoiceDetail(any()))
          .thenAnswer((_) async => Right(_entity(status: 'cancelled')));
      when(() => repo.cancelInvoice(
            id: any(named: 'id'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (c) async {
      await c.load('inv-1');
      await c.cancelInvoice('duplicate');
    },
    skip: 2,
    expect: () => [
      predicate<InvoiceDetailLoaded>(
          (s) => s.actionMessage == 'Invoice berhasil dibatalkan'),
    ],
  );
}

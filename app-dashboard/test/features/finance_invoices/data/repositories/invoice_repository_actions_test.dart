import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/core/network/network_info.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/data/models/invoice_detail_model.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/data/models/invoice_stats_model.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/data/repositories/invoice_repository_impl.dart';

class _MockDataSource extends Mock implements InvoiceRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockDataSource ds;
  late _MockNetworkInfo network;
  late InvoiceRepositoryImpl repo;

  setUp(() {
    ds = _MockDataSource();
    network = _MockNetworkInfo();
    repo = InvoiceRepositoryImpl(remoteDataSource: ds, networkInfo: network);
    when(() => network.isConnected).thenAnswer((_) async => true);
  });

  DioException _dioErr(String msg) => DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
          data: {'error': msg},
        ),
        message: msg,
      );

  group('getStats', () {
    test('returns Right(stats) on success', () async {
      when(() => ds.getStats()).thenAnswer(
        (_) async => const InvoiceStatsModel(
          totalCount: 5,
          paidCount: 2,
          paidAmount: 200000,
          outstandingCount: 2,
          outstandingAmount: 200000,
          overdueCount: 1,
          overdueAmount: 100000,
        ),
      );

      final result = await repo.getStats();
      expect(result.isRight(), true);
    });

    test('returns Left(ServerFailure) on DioException', () async {
      when(() => ds.getStats()).thenThrow(_dioErr('boom'));
      final result = await repo.getStats();
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (_) => null), isA<ServerFailure>());
    });
  });

  group('getInvoiceDetail', () {
    test('returns Right(entity) on success', () async {
      final now = DateTime.now();
      when(() => ds.getInvoiceDetail(any())).thenAnswer(
        (_) async => InvoiceDetailModel(
          id: 'inv-1',
          invoiceNumber: 'INV-1',
          studentName: 'A',
          studentContact: '081',
          batchCode: 'B',
          batchName: 'Batch',
          courseTypeName: 'Reg',
          paymentMethod: 'upfront',
          amount: 100,
          createdAt: now,
          dueDate: now,
          status: 'sent',
          source: 'auto',
          paymentHistory: const [],
        ),
      );

      final result = await repo.getInvoiceDetail('inv-1');
      expect(result.isRight(), true);
      verify(() => ds.getInvoiceDetail('inv-1')).called(1);
    });

    test('returns Left(ServerFailure) on DioException', () async {
      when(() => ds.getInvoiceDetail(any())).thenThrow(_dioErr('not found'));
      final result = await repo.getInvoiceDetail('inv-1');
      expect(result.isLeft(), true);
    });
  });

  group('markAsPaid', () {
    test('returns Right(null) on success and forwards body fields', () async {
      when(() => ds.markAsPaid(
            id: any(named: 'id'),
            paidAt: any(named: 'paidAt'),
            paidAmount: any(named: 'paidAmount'),
            paymentProof: any(named: 'paymentProof'),
            accountCode: any(named: 'accountCode'),
          )).thenAnswer((_) async {});

      final result = await repo.markAsPaid(
        id: 'inv-1',
        paidAt: '2026-05-03',
        paidAmount: 100,
        paymentProof: 'p',
        accountCode: '1101',
      );

      expect(result.isRight(), true);
      verify(() => ds.markAsPaid(
            id: 'inv-1',
            paidAt: '2026-05-03',
            paidAmount: 100,
            paymentProof: 'p',
            accountCode: '1101',
          )).called(1);
    });

    test('returns Left on DioException', () async {
      when(() => ds.markAsPaid(
            id: any(named: 'id'),
            paidAt: any(named: 'paidAt'),
            paidAmount: any(named: 'paidAmount'),
            paymentProof: any(named: 'paymentProof'),
            accountCode: any(named: 'accountCode'),
          )).thenThrow(_dioErr('paid_failed'));
      final result =
          await repo.markAsPaid(id: 'inv-1', paidAt: '2026-05-03');
      expect(result.isLeft(), true);
    });
  });

  group('sendInvoice', () {
    test('returns Right(null) on success', () async {
      when(() => ds.sendInvoice(any())).thenAnswer((_) async {});
      final result = await repo.sendInvoice('inv-1');
      expect(result.isRight(), true);
      verify(() => ds.sendInvoice('inv-1')).called(1);
    });

    test('returns Left(ServerFailure) on DioException', () async {
      when(() => ds.sendInvoice(any())).thenThrow(_dioErr('cannot send'));
      final result = await repo.sendInvoice('inv-1');
      expect(result.isLeft(), true);
      final fail = result.fold((l) => l, (_) => null) as ServerFailure;
      expect(fail.message, 'cannot send');
    });
  });

  group('cancelInvoice', () {
    test('returns Right(null) on success', () async {
      when(() => ds.cancelInvoice(
            id: any(named: 'id'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});
      final result =
          await repo.cancelInvoice(id: 'inv-1', reason: 'duplicate');
      expect(result.isRight(), true);
    });

    test('returns Left on DioException', () async {
      when(() => ds.cancelInvoice(
            id: any(named: 'id'),
            reason: any(named: 'reason'),
          )).thenThrow(_dioErr('failed'));
      final result =
          await repo.cancelInvoice(id: 'inv-1', reason: 'duplicate');
      expect(result.isLeft(), true);
    });
  });
}

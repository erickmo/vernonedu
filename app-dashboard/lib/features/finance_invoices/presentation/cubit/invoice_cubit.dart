import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../../domain/usecases/create_manual_invoice_usecase.dart';
import '../../domain/usecases/get_invoice_detail_usecase.dart';
import '../../domain/usecases/get_invoice_list_usecase.dart';
import '../../domain/usecases/get_invoice_stats_usecase.dart';
import '../../domain/usecases/mark_invoice_paid_usecase.dart';
import '../../domain/usecases/resend_invoice_usecase.dart';
import 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final GetInvoiceStatsUseCase getStats;
  final GetInvoiceListUseCase getInvoices;
  final GetInvoiceDetailUseCase getDetail;
  final MarkInvoicePaidUseCase markPaid;
  final ResendInvoiceUseCase resend;
  final CancelInvoiceUseCase cancel;
  final CreateManualInvoiceUseCase createManual;

  static const int _pageSize = 20;

  InvoiceCubit({
    required this.getStats,
    required this.getInvoices,
    required this.getDetail,
    required this.markPaid,
    required this.resend,
    required this.cancel,
    required this.createManual,
  }) : super(const InvoiceInitial());

  Future<void> loadAll({InvoiceFilterState? filter}) async {
    final f = filter ?? const InvoiceFilterState();
    emit(const InvoiceLoading());

    final results = await Future.wait([
      getStats(),
      getInvoices(
        offset: 0,
        limit: _pageSize,
        invoiceNumber: f.invoiceNumber.isEmpty ? null : f.invoiceNumber,
        studentName: f.studentName.isEmpty ? null : f.studentName,
        status: f.status.isEmpty ? null : f.status,
        batchId: f.batchId.isEmpty ? null : f.batchId,
        paymentMethod: f.paymentMethod.isEmpty ? null : f.paymentMethod,
        fromDate: f.fromDate,
        toDate: f.toDate,
      ),
    ]);

    final statsResult = results[0];
    final invoicesResult = results[1];

    String? errorMsg;
    final statsData = statsResult.fold((failure) {
      errorMsg = failure.message;
      return null;
    }, (data) => data);

    if (errorMsg != null) {
      emit(InvoiceError(errorMsg!));
      return;
    }

    final invoicesData = invoicesResult.fold((failure) {
      errorMsg = failure.message;
      return null;
    }, (data) => data);

    if (errorMsg != null) {
      emit(InvoiceError(errorMsg!));
      return;
    }

    final invoiceList = invoicesData as dynamic;
    emit(InvoiceLoaded(
      stats: statsData as dynamic,
      invoices: invoiceList,
      currentPage: 0,
      hasMore: (invoiceList as List).length >= _pageSize,
      filter: f,
    ));
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! InvoiceLoaded) return;
    if (!current.hasMore) return;

    final nextPage = current.currentPage + 1;
    final result = await getInvoices(
      offset: nextPage * _pageSize,
      limit: _pageSize,
      invoiceNumber: current.filter.invoiceNumber.isEmpty
          ? null
          : current.filter.invoiceNumber,
      studentName: current.filter.studentName.isEmpty
          ? null
          : current.filter.studentName,
      status: current.filter.status.isEmpty ? null : current.filter.status,
      batchId: current.filter.batchId.isEmpty ? null : current.filter.batchId,
      paymentMethod: current.filter.paymentMethod.isEmpty
          ? null
          : current.filter.paymentMethod,
      fromDate: current.filter.fromDate,
      toDate: current.filter.toDate,
    );

    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (newItems) {
        final allItems = [...current.invoices, ...newItems];
        emit(current.copyWith(
          invoices: allItems,
          currentPage: nextPage,
          hasMore: newItems.length >= _pageSize,
        ));
      },
    );
  }

  Future<void> applyFilter(InvoiceFilterState filter) async {
    await loadAll(filter: filter);
  }

  Future<void> markAsPaid({
    required String id,
    required String paidAt,
    required String method,
    String? proofUrl,
  }) async {
    final current = state;
    if (current is! InvoiceLoaded) return;

    final result = await markPaid(
      id: id,
      paidAt: paidAt,
      method: method,
      proofUrl: proofUrl,
    );

    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) async {
        emit(InvoiceActionSuccess(
          message: 'Invoice berhasil ditandai sebagai lunas',
          previous: current,
        ));
        await loadAll(filter: current.filter);
      },
    );
  }

  Future<void> resendInvoice(String id) async {
    final current = state;
    if (current is! InvoiceLoaded) return;

    final result = await resend(id);

    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) => emit(InvoiceActionSuccess(
        message: 'Invoice berhasil dikirim ulang',
        previous: current,
      )),
    );
  }

  Future<void> cancelInvoice({
    required String id,
    required String reason,
  }) async {
    final current = state;
    if (current is! InvoiceLoaded) return;

    final result = await cancel(id: id, reason: reason);

    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) async {
        emit(InvoiceActionSuccess(
          message: 'Invoice berhasil dibatalkan',
          previous: current,
        ));
        await loadAll(filter: current.filter);
      },
    );
  }

  Future<void> createManualInvoice(Map<String, dynamic> body) async {
    final current = state;
    if (current is! InvoiceLoaded) return;

    final result = await createManual(body);

    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) async {
        emit(InvoiceActionSuccess(
          message: 'Invoice manual berhasil dibuat',
          previous: current,
        ));
        await loadAll(filter: current.filter);
      },
    );
  }
}

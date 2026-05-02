import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../../domain/usecases/get_invoice_detail_usecase.dart';
import '../../domain/usecases/mark_invoice_paid_usecase.dart';
import '../../domain/usecases/send_invoice_usecase.dart';
import 'invoice_detail_state.dart';

class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  final GetInvoiceDetailUseCase getDetail;
  final MarkInvoicePaidUseCase markPaid;
  final SendInvoiceUseCase send;
  final CancelInvoiceUseCase cancel;

  String? _currentId;

  InvoiceDetailCubit({
    required this.getDetail,
    required this.markPaid,
    required this.send,
    required this.cancel,
  }) : super(const InvoiceDetailInitial());

  Future<void> load(String id) async {
    _currentId = id;
    emit(const InvoiceDetailLoading());
    final result = await getDetail(id);
    result.fold(
      (f) => emit(InvoiceDetailError(f.message)),
      (inv) => emit(InvoiceDetailLoaded(invoice: inv)),
    );
  }

  Future<void> pay({
    required String paidAt,
    double? paidAmount,
    String? paymentProof,
    String? accountCode,
  }) async {
    if (_currentId == null) return;
    final result = await markPaid(
      id: _currentId!,
      paidAt: paidAt,
      paidAmount: paidAmount,
      paymentProof: paymentProof,
      accountCode: accountCode,
    );
    await result.fold(
      (f) async => emit(InvoiceDetailError(f.message)),
      (_) async {
        await _reloadWithMessage('Invoice berhasil ditandai lunas');
      },
    );
  }

  Future<void> sendNow() async {
    if (_currentId == null) return;
    final result = await send(_currentId!);
    await result.fold(
      (f) async => emit(InvoiceDetailError(f.message)),
      (_) async {
        await _reloadWithMessage('Invoice berhasil dikirim');
      },
    );
  }

  Future<void> cancelInvoice(String reason) async {
    if (_currentId == null) return;
    final result = await cancel(id: _currentId!, reason: reason);
    await result.fold(
      (f) async => emit(InvoiceDetailError(f.message)),
      (_) async {
        await _reloadWithMessage('Invoice berhasil dibatalkan');
      },
    );
  }

  Future<void> _reloadWithMessage(String message) async {
    if (_currentId == null) return;
    final result = await getDetail(_currentId!);
    result.fold(
      (f) => emit(InvoiceDetailError(f.message)),
      (inv) =>
          emit(InvoiceDetailLoaded(invoice: inv, actionMessage: message)),
    );
  }
}

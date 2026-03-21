import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_payable_stats_usecase.dart';
import '../../domain/usecases/get_payables_usecase.dart';
import '../../domain/usecases/mark_payable_paid_usecase.dart';
import 'payable_state.dart';

class PayableCubit extends Cubit<PayableState> {
  final GetPayableStatsUseCase getPayableStatsUseCase;
  final GetPayablesUseCase getPayablesUseCase;
  final MarkPayablePaidUseCase markPayablePaidUseCase;

  static const int _pageSize = 20;

  PayableCubit({
    required this.getPayableStatsUseCase,
    required this.getPayablesUseCase,
    required this.markPayablePaidUseCase,
  }) : super(const PayableInitial());

  Future<void> loadAll({String? type, String? status}) async {
    emit(const PayableLoading());
    final statsResult = await getPayableStatsUseCase();
    final payablesResult = await getPayablesUseCase(
      offset: 0, limit: _pageSize, type: type, status: status,
    );

    final stats = statsResult.fold(
      (f) { emit(PayableError(f.message)); return null; },
      (s) => s,
    );
    if (state is PayableError) return;

    final payables = payablesResult.fold(
      (f) { emit(PayableError(f.message)); return null; },
      (p) => p,
    );
    if (state is PayableError) return;

    emit(PayableLoaded(
      stats: stats!,
      payables: payables!,
      currentPage: 0,
      hasMore: payables.length == _pageSize,
      activeType: type,
      activeStatus: status,
    ));
  }

  Future<void> loadPage({
    int page = 0,
    String? type,
    String? status,
  }) async {
    final current = state;
    if (current is! PayableLoaded) return;

    final result = await getPayablesUseCase(
      offset: page * _pageSize,
      limit: _pageSize,
      type: type,
      status: status,
    );
    result.fold(
      (f) => emit(PayableError(f.message)),
      (payables) => emit(current.copyWith(
        payables: payables,
        currentPage: page,
        hasMore: payables.length == _pageSize,
        activeType: type,
        clearType: type == null,
        activeStatus: status,
        clearStatus: status == null,
      )),
    );
  }

  Future<bool> markAsPaid(String id, {String? paymentProof}) async {
    final result = await markPayablePaidUseCase(id, paymentProof: paymentProof);
    return result.fold(
      (f) {
        emit(PayableError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }
}

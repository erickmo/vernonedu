import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cash_flow_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../../domain/usecases/get_cash_flow_usecase.dart';

part 'cash_flow_state.dart';

class CashFlowCubit extends Cubit<CashFlowState> {
  final GetCashFlowUseCase _useCase;
  ReportFilterEntity _filter = const ReportFilterEntity();

  CashFlowCubit(this._useCase) : super(const CashFlowInitial());

  Future<void> load({ReportFilterEntity? filter}) async {
    if (filter != null) _filter = filter;
    emit(const CashFlowLoading());
    final result = await _useCase(_filter);
    result.fold(
      (failure) => emit(CashFlowError(failure.message)),
      (data) => emit(CashFlowLoaded(data: data, filter: _filter)),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/balance_sheet_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../../domain/usecases/get_balance_sheet_usecase.dart';

part 'balance_sheet_state.dart';

class BalanceSheetCubit extends Cubit<BalanceSheetState> {
  final GetBalanceSheetUseCase _useCase;
  ReportFilterEntity _filter = const ReportFilterEntity();

  BalanceSheetCubit(this._useCase) : super(const BalanceSheetInitial());

  Future<void> load({ReportFilterEntity? filter}) async {
    if (filter != null) _filter = filter;
    emit(const BalanceSheetLoading());
    final result = await _useCase(_filter);
    result.fold(
      (failure) => emit(BalanceSheetError(failure.message)),
      (data) => emit(BalanceSheetLoaded(data: data, filter: _filter)),
    );
  }
}

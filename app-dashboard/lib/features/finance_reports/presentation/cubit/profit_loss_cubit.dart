import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/profit_loss_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../../domain/usecases/get_profit_loss_usecase.dart';

part 'profit_loss_state.dart';

class ProfitLossCubit extends Cubit<ProfitLossState> {
  final GetProfitLossUseCase _useCase;
  ReportFilterEntity _filter = const ReportFilterEntity();

  ProfitLossCubit(this._useCase) : super(const ProfitLossInitial());

  Future<void> load({ReportFilterEntity? filter}) async {
    if (filter != null) _filter = filter;
    emit(const ProfitLossLoading());
    final result = await _useCase(_filter);
    result.fold(
      (failure) => emit(ProfitLossError(failure.message)),
      (data) => emit(ProfitLossLoaded(data: data, filter: _filter)),
    );
  }
}

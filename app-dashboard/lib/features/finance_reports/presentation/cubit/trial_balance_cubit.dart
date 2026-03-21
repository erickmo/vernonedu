import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../../domain/entities/trial_balance_entity.dart';
import '../../domain/usecases/get_trial_balance_usecase.dart';

part 'trial_balance_state.dart';

class TrialBalanceCubit extends Cubit<TrialBalanceState> {
  final GetTrialBalanceUseCase _useCase;
  ReportFilterEntity _filter = const ReportFilterEntity();

  TrialBalanceCubit(this._useCase) : super(const TrialBalanceInitial());

  Future<void> load({ReportFilterEntity? filter}) async {
    if (filter != null) _filter = filter;
    emit(const TrialBalanceLoading());
    final result = await _useCase(_filter);
    result.fold(
      (failure) => emit(TrialBalanceError(failure.message)),
      (data) => emit(TrialBalanceLoaded(data: data, filter: _filter)),
    );
  }
}

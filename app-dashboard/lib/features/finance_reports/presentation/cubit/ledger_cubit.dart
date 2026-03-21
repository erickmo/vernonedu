import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ledger_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../../domain/usecases/get_ledger_usecase.dart';

part 'ledger_state.dart';

class LedgerCubit extends Cubit<LedgerState> {
  final GetLedgerUseCase _useCase;
  ReportFilterEntity _filter = const ReportFilterEntity();
  String? _accountId;

  LedgerCubit(this._useCase) : super(const LedgerInitial());

  Future<void> load({ReportFilterEntity? filter, String? accountId}) async {
    if (filter != null) _filter = filter;
    if (accountId != null) _accountId = accountId;
    emit(const LedgerLoading());
    final result = await _useCase(filter: _filter, accountId: _accountId);
    result.fold(
      (failure) => emit(LedgerError(failure.message)),
      (data) => emit(LedgerLoaded(data: data, filter: _filter)),
    );
  }
}

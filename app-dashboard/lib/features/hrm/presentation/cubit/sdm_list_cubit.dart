import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_sdm_list_usecase.dart';
import 'sdm_list_state.dart';

/// Cubit untuk mengelola daftar SDM.
class SdmListCubit extends Cubit<SdmListState> {
  final GetSdmListUseCase _getSdmListUseCase;

  SdmListCubit({required GetSdmListUseCase getSdmListUseCase})
      : _getSdmListUseCase = getSdmListUseCase,
        super(const SdmListInitial());

  /// Memuat daftar semua SDM.
  Future<void> loadSdmList() async {
    emit(const SdmListLoading());
    final result = await _getSdmListUseCase();
    result.fold(
      (failure) => emit(SdmListError(failure.message)),
      (list) => emit(SdmListLoaded(list)),
    );
  }
}

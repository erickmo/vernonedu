import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_sdm_detail_usecase.dart';
import 'sdm_detail_state.dart';

/// Cubit untuk mengelola detail satu SDM.
class SdmDetailCubit extends Cubit<SdmDetailState> {
  final GetSdmDetailUseCase _getSdmDetailUseCase;

  SdmDetailCubit({required GetSdmDetailUseCase getSdmDetailUseCase})
      : _getSdmDetailUseCase = getSdmDetailUseCase,
        super(const SdmDetailInitial());

  /// Memuat detail SDM berdasarkan [id].
  Future<void> loadDetail(String id) async {
    emit(const SdmDetailLoading());
    final result = await _getSdmDetailUseCase(id);
    result.fold(
      (failure) => emit(SdmDetailError(failure.message)),
      (detail) => emit(SdmDetailLoaded(detail)),
    );
  }
}

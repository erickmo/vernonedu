import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_partner_detail_usecase.dart';
import '../../domain/usecases/add_mou_usecase.dart';
import 'partner_detail_state.dart';

class PartnerDetailCubit extends Cubit<PartnerDetailState> {
  final GetPartnerDetailUseCase _getPartnerDetail;
  final AddMouUseCase _addMou;

  PartnerDetailCubit({
    required GetPartnerDetailUseCase getPartnerDetail,
    required AddMouUseCase addMou,
  })  : _getPartnerDetail = getPartnerDetail,
        _addMou = addMou,
        super(const PartnerDetailInitial());

  Future<void> loadDetail(String partnerId) async {
    emit(const PartnerDetailLoading());
    final result = await _getPartnerDetail(partnerId);
    result.fold(
      (failure) => emit(PartnerDetailError(failure.message)),
      (data) => emit(PartnerDetailLoaded(
        partner: data.partner,
        mous: data.mous,
        logs: data.logs,
      )),
    );
  }

  Future<bool> addMOU(String partnerId, Map<String, dynamic> body) async {
    final result = await _addMou(partnerId, body);
    return result.fold(
      (failure) {
        emit(PartnerDetailError(failure.message));
        return false;
      },
      (_) {
        loadDetail(partnerId);
        return true;
      },
    );
  }
}

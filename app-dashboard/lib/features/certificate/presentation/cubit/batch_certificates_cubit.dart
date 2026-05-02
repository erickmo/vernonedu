import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/certificate_entity.dart';
import '../../domain/usecases/list_certificates_by_batch_usecase.dart';
import '../../domain/usecases/revoke_certificate_usecase.dart';

abstract class BatchCertificatesState extends Equatable {
  const BatchCertificatesState();
  @override
  List<Object?> get props => [];
}

class BatchCertificatesInitial extends BatchCertificatesState {
  const BatchCertificatesInitial();
}

class BatchCertificatesLoading extends BatchCertificatesState {
  const BatchCertificatesLoading();
}

class BatchCertificatesLoaded extends BatchCertificatesState {
  final List<CertificateEntity> items;
  const BatchCertificatesLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class BatchCertificatesError extends BatchCertificatesState {
  final String message;
  const BatchCertificatesError(this.message);
  @override
  List<Object?> get props => [message];
}

class BatchCertificatesCubit extends Cubit<BatchCertificatesState> {
  final ListCertificatesByBatchUseCase _listByBatch;
  final RevokeCertificateUseCase _revoke;

  String? _currentBatchId;

  BatchCertificatesCubit({
    required ListCertificatesByBatchUseCase listByBatch,
    required RevokeCertificateUseCase revoke,
  })  : _listByBatch = listByBatch,
        _revoke = revoke,
        super(const BatchCertificatesInitial());

  Future<void> load(String batchId) async {
    _currentBatchId = batchId;
    emit(const BatchCertificatesLoading());
    final result = await _listByBatch(batchId);
    result.fold(
      (f) => emit(BatchCertificatesError(f.message)),
      (items) => emit(BatchCertificatesLoaded(items)),
    );
  }

  Future<bool> revoke({
    required String certificateId,
    required String reason,
  }) async {
    final result = await _revoke(id: certificateId, reason: reason);
    return await result.fold(
      (f) async {
        emit(BatchCertificatesError(f.message));
        return false;
      },
      (_) async {
        final bid = _currentBatchId;
        if (bid != null) {
          await load(bid);
        }
        return true;
      },
    );
  }
}

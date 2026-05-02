import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/certificate_entity.dart';
import '../../domain/usecases/list_certificates_by_batch_usecase.dart';

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

  BatchCertificatesCubit({
    required ListCertificatesByBatchUseCase listByBatch,
  })  : _listByBatch = listByBatch,
        super(const BatchCertificatesInitial());

  Future<void> load(String batchId) async {
    emit(const BatchCertificatesLoading());
    final result = await _listByBatch(batchId);
    result.fold(
      (f) => emit(BatchCertificatesError(f.message)),
      (items) => emit(BatchCertificatesLoaded(items)),
    );
  }
}

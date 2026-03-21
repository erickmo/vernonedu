import 'package:equatable/equatable.dart';

import '../../domain/entities/sdm_entity.dart';

abstract class SdmDetailState extends Equatable {
  const SdmDetailState();

  @override
  List<Object?> get props => [];
}

class SdmDetailInitial extends SdmDetailState {
  const SdmDetailInitial();
}

class SdmDetailLoading extends SdmDetailState {
  const SdmDetailLoading();
}

class SdmDetailLoaded extends SdmDetailState {
  final SdmDetailEntity detail;

  const SdmDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class SdmDetailError extends SdmDetailState {
  final String message;

  const SdmDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

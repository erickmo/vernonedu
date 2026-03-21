import 'package:equatable/equatable.dart';

import '../../domain/entities/sdm_entity.dart';

abstract class SdmListState extends Equatable {
  const SdmListState();

  @override
  List<Object?> get props => [];
}

class SdmListInitial extends SdmListState {
  const SdmListInitial();
}

class SdmListLoading extends SdmListState {
  const SdmListLoading();
}

class SdmListLoaded extends SdmListState {
  final List<SdmEntity> sdmList;

  const SdmListLoaded(this.sdmList);

  @override
  List<Object?> get props => [sdmList];
}

class SdmListError extends SdmListState {
  final String message;

  const SdmListError(this.message);

  @override
  List<Object?> get props => [message];
}

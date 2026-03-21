import 'package:equatable/equatable.dart';

import '../../domain/entities/batch_entity.dart';

abstract class BatchListState extends Equatable {
  const BatchListState();

  @override
  List<Object?> get props => [];
}

class BatchListInitial extends BatchListState {
  const BatchListInitial();
}

class BatchListLoading extends BatchListState {
  const BatchListLoading();
}

class BatchListLoaded extends BatchListState {
  final List<BatchEntity> batches;

  const BatchListLoaded(this.batches);

  @override
  List<Object?> get props => [batches];
}

class BatchListError extends BatchListState {
  final String message;

  const BatchListError(this.message);

  @override
  List<Object?> get props => [message];
}

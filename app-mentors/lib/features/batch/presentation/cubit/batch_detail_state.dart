import 'package:equatable/equatable.dart';

import '../../domain/entities/batch_detail_entity.dart';

abstract class BatchDetailState extends Equatable {
  const BatchDetailState();

  @override
  List<Object?> get props => [];
}

class BatchDetailInitial extends BatchDetailState {
  const BatchDetailInitial();
}

class BatchDetailLoading extends BatchDetailState {
  const BatchDetailLoading();
}

class BatchDetailLoaded extends BatchDetailState {
  final BatchDetailEntity detail;
  final bool isAssigning;

  const BatchDetailLoaded(this.detail, {this.isAssigning = false});

  BatchDetailLoaded copyWith({BatchDetailEntity? detail, bool? isAssigning}) =>
      BatchDetailLoaded(
        detail ?? this.detail,
        isAssigning: isAssigning ?? this.isAssigning,
      );

  @override
  List<Object?> get props => [detail, isAssigning];
}

class BatchDetailError extends BatchDetailState {
  final String message;

  const BatchDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

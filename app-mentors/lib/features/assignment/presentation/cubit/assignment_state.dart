import 'package:equatable/equatable.dart';

import '../../domain/entities/facilitator_entity.dart';

abstract class AssignmentState extends Equatable {
  const AssignmentState();

  @override
  List<Object?> get props => [];
}

class AssignmentInitial extends AssignmentState {
  const AssignmentInitial();
}

class AssignmentLoading extends AssignmentState {
  const AssignmentLoading();
}

class AssignmentLoaded extends AssignmentState {
  final List<FacilitatorEntity> facilitators;
  final String? selectedId;

  const AssignmentLoaded({required this.facilitators, this.selectedId});

  AssignmentLoaded copyWith({
    List<FacilitatorEntity>? facilitators,
    String? selectedId,
  }) =>
      AssignmentLoaded(
        facilitators: facilitators ?? this.facilitators,
        selectedId: selectedId ?? this.selectedId,
      );

  @override
  List<Object?> get props => [facilitators, selectedId];
}

class AssignmentError extends AssignmentState {
  final String message;

  const AssignmentError(this.message);

  @override
  List<Object?> get props => [message];
}

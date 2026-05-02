import 'package:equatable/equatable.dart';
import '../../domain/entities/course_version_entity.dart';

abstract class PendingApprovalsState extends Equatable {
  const PendingApprovalsState();
  @override
  List<Object?> get props => [];
}

class PendingApprovalsInitial extends PendingApprovalsState {
  const PendingApprovalsInitial();
}

class PendingApprovalsLoading extends PendingApprovalsState {
  const PendingApprovalsLoading();
}

class PendingApprovalsLoaded extends PendingApprovalsState {
  final List<CourseVersionEntity> versions;
  const PendingApprovalsLoaded(this.versions);

  @override
  List<Object?> get props => [versions];
}

class PendingApprovalsError extends PendingApprovalsState {
  final String message;
  const PendingApprovalsError(this.message);

  @override
  List<Object?> get props => [message];
}

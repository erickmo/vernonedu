import 'package:equatable/equatable.dart';
import '../../domain/entities/course_batch_entity.dart';

abstract class CourseBatchState extends Equatable {
  const CourseBatchState();
  @override
  List<Object?> get props => [];
}

class CourseBatchInitial extends CourseBatchState { const CourseBatchInitial(); }
class CourseBatchLoading extends CourseBatchState { const CourseBatchLoading(); }
class CourseBatchLoaded extends CourseBatchState {
  final List<CourseBatchEntity> batches;
  const CourseBatchLoaded(this.batches);
  @override
  List<Object?> get props => [batches];
}
class CourseBatchError extends CourseBatchState {
  final String message;
  const CourseBatchError(this.message);
  @override
  List<Object?> get props => [message];
}

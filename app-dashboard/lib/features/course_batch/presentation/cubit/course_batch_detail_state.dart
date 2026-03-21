import 'package:equatable/equatable.dart';
import '../../domain/entities/course_batch_detail_entity.dart';

abstract class CourseBatchDetailState extends Equatable {
  const CourseBatchDetailState();
  @override
  List<Object?> get props => [];
}

class CourseBatchDetailInitial extends CourseBatchDetailState {
  const CourseBatchDetailInitial();
}

class CourseBatchDetailLoading extends CourseBatchDetailState {
  const CourseBatchDetailLoading();
}

class CourseBatchDetailLoaded extends CourseBatchDetailState {
  final CourseBatchDetailEntity detail;
  const CourseBatchDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

class CourseBatchDetailError extends CourseBatchDetailState {
  final String message;
  const CourseBatchDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

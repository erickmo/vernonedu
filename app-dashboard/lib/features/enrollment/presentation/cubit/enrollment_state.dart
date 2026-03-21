import 'package:equatable/equatable.dart';
import '../../domain/entities/enrollment_batch_summary_entity.dart';
import '../../domain/entities/enrollment_entity.dart';

abstract class EnrollmentState extends Equatable {
  const EnrollmentState();
  @override
  List<Object?> get props => [];
}

class EnrollmentInitial extends EnrollmentState {
  const EnrollmentInitial();
}

class EnrollmentLoading extends EnrollmentState {
  const EnrollmentLoading();
}

class EnrollmentLoaded extends EnrollmentState {
  final List<EnrollmentEntity> enrollments;
  const EnrollmentLoaded(this.enrollments);
  @override
  List<Object?> get props => [enrollments];
}

class EnrollmentSummaryLoading extends EnrollmentState {
  const EnrollmentSummaryLoading();
}

class EnrollmentSummaryLoaded extends EnrollmentState {
  final List<EnrollmentBatchSummaryEntity> summaries;
  const EnrollmentSummaryLoaded(this.summaries);
  @override
  List<Object?> get props => [summaries];
}

class EnrollmentError extends EnrollmentState {
  final String message;
  const EnrollmentError(this.message);
  @override
  List<Object?> get props => [message];
}

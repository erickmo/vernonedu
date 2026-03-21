import 'package:equatable/equatable.dart';

class DepartmentSummaryEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final int courseCount;
  final int batchUpcoming;
  final int batchOngoing;
  final int batchCompleted;
  final int paidEnrollmentCount;

  const DepartmentSummaryEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.courseCount,
    required this.batchUpcoming,
    required this.batchOngoing,
    required this.batchCompleted,
    required this.paidEnrollmentCount,
  });

  int get totalBatches => batchUpcoming + batchOngoing + batchCompleted;

  @override
  List<Object?> get props => [id];
}

import 'package:equatable/equatable.dart';

import 'batch_entity.dart';
import 'enrolled_student_entity.dart';

class BatchModuleEntity extends Equatable {
  final String id;
  final String title;
  final int order;
  final String? contentType;
  final bool isCompleted;

  const BatchModuleEntity({
    required this.id,
    required this.title,
    required this.order,
    this.contentType,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [id];
}

class BatchDetailEntity extends Equatable {
  final BatchEntity batch;
  final List<EnrolledStudentEntity> students;
  final List<BatchModuleEntity> modules;

  const BatchDetailEntity({
    required this.batch,
    required this.students,
    required this.modules,
  });

  @override
  List<Object?> get props => [batch.id];
}

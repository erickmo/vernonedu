import '../../domain/entities/batch_detail_entity.dart';
import 'batch_model.dart';
import 'enrolled_student_model.dart';

class BatchModuleModel {
  final String id;
  final String title;
  final int order;
  final String? contentType;
  final bool isCompleted;

  const BatchModuleModel({
    required this.id,
    required this.title,
    required this.order,
    this.contentType,
    required this.isCompleted,
  });

  factory BatchModuleModel.fromJson(Map<String, dynamic> json) =>
      BatchModuleModel(
        id: json['id'] as String,
        title: json['title'] as String,
        order: json['order'] as int? ?? 0,
        contentType: json['content_type'] as String?,
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  BatchModuleEntity toEntity() => BatchModuleEntity(
        id: id,
        title: title,
        order: order,
        contentType: contentType,
        isCompleted: isCompleted,
      );
}

class BatchDetailModel {
  final BatchModel batch;
  final List<EnrolledStudentModel> students;
  final List<BatchModuleModel> modules;

  const BatchDetailModel({
    required this.batch,
    required this.students,
    required this.modules,
  });

  factory BatchDetailModel.fromJson(Map<String, dynamic> json) {
    final batchJson = json['batch'] as Map<String, dynamic>? ?? json;
    final studentsJson = json['students'] as List? ?? [];
    final modulesJson = json['modules'] as List? ?? [];
    return BatchDetailModel(
      batch: BatchModel.fromJson(batchJson),
      students: studentsJson
          .map((e) => EnrolledStudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      modules: modulesJson
          .map((e) => BatchModuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  BatchDetailEntity toEntity() => BatchDetailEntity(
        batch: batch.toEntity(),
        students: students.map((s) => s.toEntity()).toList(),
        modules: modules.map((m) => m.toEntity()).toList(),
      );
}

import '../../domain/entities/student_crm_log_entity.dart';

class StudentCrmLogModel {
  final String id;
  final String studentId;
  final DateTime date;
  final String contactedBy;
  final String contactMethod;
  final String response;

  const StudentCrmLogModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.contactedBy,
    required this.contactMethod,
    required this.response,
  });

  factory StudentCrmLogModel.fromJson(Map<String, dynamic> json) =>
      StudentCrmLogModel(
        id: json['id'] as String? ?? '',
        studentId: json['student_id'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
            : json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String) ??
                    DateTime.now()
                : DateTime.now(),
        contactedBy: json['contacted_by'] as String? ?? '',
        contactMethod: json['contact_method'] as String? ?? 'phone',
        response: json['response'] as String? ?? '',
      );

  StudentCrmLogEntity toEntity() => StudentCrmLogEntity(
        id: id,
        studentId: studentId,
        date: date,
        contactedBy: contactedBy,
        contactMethod: contactMethod,
        response: response,
      );
}

import '../../domain/entities/department_talentpool_entity.dart';

class DepartmentTalentPoolModel {
  final String id;
  final String participantId;
  final String participantName;
  final String participantEmail;
  final String status;
  final int joinedAt;
  final double? testScore;

  const DepartmentTalentPoolModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantEmail,
    required this.status,
    required this.joinedAt,
    this.testScore,
  });

  factory DepartmentTalentPoolModel.fromJson(Map<String, dynamic> json) {
    return DepartmentTalentPoolModel(
      id: json['id'] as String? ?? '',
      participantId: json['participant_id'] as String? ?? '',
      participantName: json['participant_name'] as String? ?? '',
      participantEmail: json['participant_email'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      joinedAt: json['joined_at'] as int? ?? 0,
      testScore: (json['test_score'] as num?)?.toDouble(),
    );
  }

  DepartmentTalentPoolEntity toEntity() => DepartmentTalentPoolEntity(
        id: id,
        participantId: participantId,
        participantName: participantName,
        participantEmail: participantEmail,
        status: status,
        joinedAt: joinedAt,
        testScore: testScore,
      );
}

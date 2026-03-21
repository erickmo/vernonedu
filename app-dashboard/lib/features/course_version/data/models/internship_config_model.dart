import '../../domain/entities/internship_config_entity.dart';

class InternshipConfigModel {
  final String id;
  final String courseVersionId;
  final String partnerCompanyName;
  final String partnerCompanyId;
  final String positionTitle;
  final int durationWeeks;
  final String supervisorName;
  final String supervisorContact;
  final String mouDocumentUrl;
  final bool isCompanyProvided;
  final int createdAt;
  final int updatedAt;

  const InternshipConfigModel({
    required this.id,
    required this.courseVersionId,
    required this.partnerCompanyName,
    required this.partnerCompanyId,
    required this.positionTitle,
    required this.durationWeeks,
    required this.supervisorName,
    required this.supervisorContact,
    required this.mouDocumentUrl,
    required this.isCompanyProvided,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InternshipConfigModel.fromJson(Map<String, dynamic> json) {
    return InternshipConfigModel(
      id: json['id'] as String? ?? '',
      courseVersionId: json['course_version_id'] as String? ?? '',
      partnerCompanyName: json['partner_company_name'] as String? ?? '',
      partnerCompanyId: json['partner_company_id'] as String? ?? '',
      positionTitle: json['position_title'] as String? ?? '',
      durationWeeks: json['duration_weeks'] as int? ?? 4,
      supervisorName: json['supervisor_name'] as String? ?? '',
      supervisorContact: json['supervisor_contact'] as String? ?? '',
      mouDocumentUrl: json['mou_document_url'] as String? ?? '',
      isCompanyProvided: json['is_company_provided'] as bool? ?? true,
      createdAt: json['created_at'] as int? ?? 0,
      updatedAt: json['updated_at'] as int? ?? 0,
    );
  }

  InternshipConfigEntity toEntity() => InternshipConfigEntity(
        id: id,
        courseVersionId: courseVersionId,
        partnerCompanyName: partnerCompanyName,
        partnerCompanyId: partnerCompanyId,
        positionTitle: positionTitle,
        durationWeeks: durationWeeks,
        supervisorName: supervisorName,
        supervisorContact: supervisorContact,
        mouDocumentUrl: mouDocumentUrl,
        isCompanyProvided: isCompanyProvided,
      );
}

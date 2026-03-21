import '../../domain/entities/certificate_template_entity.dart';

class CertificateTemplateModel {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> templateData;
  final DateTime createdAt;

  const CertificateTemplateModel({
    required this.id,
    required this.name,
    required this.type,
    required this.templateData,
    required this.createdAt,
  });

  factory CertificateTemplateModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return DateTime.now();
      }
    }

    return CertificateTemplateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'participant',
      templateData:
          (json['template_data'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
    );
  }

  CertificateTemplateEntity toEntity() => CertificateTemplateEntity(
        id: id,
        name: name,
        type: type,
        templateData: templateData,
        createdAt: createdAt,
      );
}

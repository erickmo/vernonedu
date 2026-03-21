import 'package:equatable/equatable.dart';

class CertificateTemplateEntity extends Equatable {
  final String id;
  final String name;
  final String type; // participant | competency
  final Map<String, dynamic> templateData;
  final DateTime createdAt;

  const CertificateTemplateEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.templateData,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, type];
}

import '../../domain/entities/certificate_template_entity.dart';

/// Default fallback values keep the entity valid even if the backend stores
/// a partial / legacy `template_data` blob.
const _kDefaultTitle = 'Sertifikat';
const _kDefaultFont = 'Roboto';
const _kDefaultTitleSize = 36.0;
const _kDefaultTitleX = 0.4;
const _kDefaultTitleY = 0.15;
const _kDefaultBodyX = 0.1;
const _kDefaultBodyY = 0.4;
const _kDefaultQrPosition = 'bottom-right';

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
    DateTime parseDate(dynamic v) {
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
      createdAt: parseDate(json['created_at'] ?? json['updated_at']),
    );
  }

  CertificateTemplateEntity toEntity() {
    final td = templateData;
    final blocks = (td['signatureBlocks'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(SignatureBlockEntity.fromJson)
            .toList() ??
        const <SignatureBlockEntity>[];

    return CertificateTemplateEntity(
      id: id,
      name: name,
      type: type,
      title: td['title'] as String? ?? _kDefaultTitle,
      bodyText: td['bodyText'] as String? ?? '',
      fontFamily: td['fontFamily'] as String? ?? _kDefaultFont,
      titleSize: (td['titleSize'] as num?)?.toDouble() ?? _kDefaultTitleSize,
      titleX: (td['titleX'] as num?)?.toDouble() ?? _kDefaultTitleX,
      titleY: (td['titleY'] as num?)?.toDouble() ?? _kDefaultTitleY,
      bodyX: (td['bodyX'] as num?)?.toDouble() ?? _kDefaultBodyX,
      bodyY: (td['bodyY'] as num?)?.toDouble() ?? _kDefaultBodyY,
      backgroundUrl: td['backgroundUrl'] as String?,
      qrPosition: td['qrPosition'] as String? ?? _kDefaultQrPosition,
      signatureBlocks: blocks,
      templateData: td,
      createdAt: createdAt,
    );
  }
}

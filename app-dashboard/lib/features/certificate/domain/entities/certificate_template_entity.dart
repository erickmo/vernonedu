import 'package:equatable/equatable.dart';

/// Block of signature placement metadata. Coordinates are normalized
/// (0.0–1.0) relative to the A4 canvas so the renderer can scale them.
class SignatureBlockEntity extends Equatable {
  final String name;
  final String role;
  final double x;
  final double y;

  const SignatureBlockEntity({
    required this.name,
    required this.role,
    required this.x,
    required this.y,
  });

  SignatureBlockEntity copyWith({
    String? name,
    String? role,
    double? x,
    double? y,
  }) =>
      SignatureBlockEntity(
        name: name ?? this.name,
        role: role ?? this.role,
        x: x ?? this.x,
        y: y ?? this.y,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'x': x,
        'y': y,
      };

  factory SignatureBlockEntity.fromJson(Map<String, dynamic> json) =>
      SignatureBlockEntity(
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        x: (json['x'] as num?)?.toDouble() ?? 0.5,
        y: (json['y'] as num?)?.toDouble() ?? 0.8,
      );

  @override
  List<Object?> get props => [name, role, x, y];
}

/// Certificate template entity. The backend stores all design fields inside
/// `template_data` as a JSON blob. The presentation layer expands that blob
/// into typed fields below for the live preview / form binding.
class CertificateTemplateEntity extends Equatable {
  final String id;
  final String name;
  final String type; // participant | competency

  // Design fields (persisted under template_data)
  final String title;
  final String bodyText;
  final String fontFamily;
  final double titleSize;
  final double titleX;
  final double titleY;
  final double bodyX;
  final double bodyY;
  final String? backgroundUrl;
  final String qrPosition; // top-left | top-right | bottom-left | bottom-right | none
  final List<SignatureBlockEntity> signatureBlocks;

  final Map<String, dynamic> templateData;
  final DateTime createdAt;

  const CertificateTemplateEntity({
    required this.id,
    required this.name,
    required this.type,
    this.title = 'Sertifikat',
    this.bodyText = '',
    this.fontFamily = 'Roboto',
    this.titleSize = 36,
    this.titleX = 0.4,
    this.titleY = 0.15,
    this.bodyX = 0.1,
    this.bodyY = 0.4,
    this.backgroundUrl,
    this.qrPosition = 'bottom-right',
    this.signatureBlocks = const [],
    this.templateData = const {},
    required this.createdAt,
  });

  CertificateTemplateEntity copyWith({
    String? id,
    String? name,
    String? type,
    String? title,
    String? bodyText,
    String? fontFamily,
    double? titleSize,
    double? titleX,
    double? titleY,
    double? bodyX,
    double? bodyY,
    String? backgroundUrl,
    bool clearBackground = false,
    String? qrPosition,
    List<SignatureBlockEntity>? signatureBlocks,
    Map<String, dynamic>? templateData,
    DateTime? createdAt,
  }) =>
      CertificateTemplateEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        title: title ?? this.title,
        bodyText: bodyText ?? this.bodyText,
        fontFamily: fontFamily ?? this.fontFamily,
        titleSize: titleSize ?? this.titleSize,
        titleX: titleX ?? this.titleX,
        titleY: titleY ?? this.titleY,
        bodyX: bodyX ?? this.bodyX,
        bodyY: bodyY ?? this.bodyY,
        backgroundUrl:
            clearBackground ? null : (backgroundUrl ?? this.backgroundUrl),
        qrPosition: qrPosition ?? this.qrPosition,
        signatureBlocks: signatureBlocks ?? this.signatureBlocks,
        templateData: templateData ?? this.templateData,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Serializes design fields into the JSON blob that backend stores under
  /// `template_data`.
  Map<String, dynamic> toTemplateDataJson() => {
        'title': title,
        'bodyText': bodyText,
        'fontFamily': fontFamily,
        'titleSize': titleSize,
        'titleX': titleX,
        'titleY': titleY,
        'bodyX': bodyX,
        'bodyY': bodyY,
        if (backgroundUrl != null) 'backgroundUrl': backgroundUrl,
        'qrPosition': qrPosition,
        'signatureBlocks': signatureBlocks.map((s) => s.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        title,
        bodyText,
        fontFamily,
        titleSize,
        titleX,
        titleY,
        bodyX,
        bodyY,
        backgroundUrl,
        qrPosition,
        signatureBlocks,
      ];
}

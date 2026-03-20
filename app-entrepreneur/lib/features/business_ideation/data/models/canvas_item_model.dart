import '../../domain/entities/canvas_item_entity.dart';

class CanvasItemModel extends CanvasItemEntity {
  const CanvasItemModel({
    required super.id,
    required super.businessId,
    required super.canvasType,
    required super.sectionId,
    required super.text,
    required super.note,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CanvasItemModel.fromJson(Map<String, dynamic> json) {
    return CanvasItemModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      canvasType: json['canvas_type']?.toString() ?? '',
      sectionId: json['section_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'canvas_type': canvasType,
      'section_id': sectionId,
      'text': text,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

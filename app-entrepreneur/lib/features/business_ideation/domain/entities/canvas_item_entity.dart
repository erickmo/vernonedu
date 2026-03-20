class CanvasItemEntity {
  final String id;
  final String businessId;
  final String canvasType; // "bmc" | "vpc" | "design-thinking" | "pestel" | "flywheel"
  final String sectionId;
  final String text;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanvasItemEntity({
    required this.id,
    required this.businessId,
    required this.canvasType,
    required this.sectionId,
    required this.text,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
}

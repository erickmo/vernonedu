import '../../domain/entities/course_type_entity.dart';

// Model data layer untuk CourseType — bertanggung jawab parsing JSON dari API
class CourseTypeModel {
  final String id;
  final String masterCourseId;
  final String typeName;
  final bool isActive;
  final String priceType;
  final int? priceMin;
  final int? priceMax;
  final String priceCurrency;
  final String priceNotes;
  final String targetAudience;
  final List<String> extraDocs;
  final String certificationType;
  final int? minParticipants;
  final int? maxParticipants;
  final Map<String, String>? componentFailureConfig;

  const CourseTypeModel({
    required this.id,
    required this.masterCourseId,
    required this.typeName,
    required this.isActive,
    required this.priceType,
    this.priceMin,
    this.priceMax,
    required this.priceCurrency,
    required this.priceNotes,
    required this.targetAudience,
    required this.extraDocs,
    required this.certificationType,
    this.minParticipants,
    this.maxParticipants,
    this.componentFailureConfig,
  });

  factory CourseTypeModel.fromJson(Map<String, dynamic> json) {
    // Parse componentFailureConfig jika ada
    Map<String, String>? failureConfig;
    final rawConfig = json['component_failure_config'];
    if (rawConfig is Map) {
      failureConfig = rawConfig.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return CourseTypeModel(
      id: json['id'] as String? ?? '',
      masterCourseId: json['master_course_id'] as String? ?? '',
      typeName: json['type_name'] as String? ?? 'regular',
      isActive: json['is_active'] as bool? ?? true,
      priceType: json['price_type'] as String? ?? 'by_request',
      priceMin: json['price_min'] as int?,
      priceMax: json['price_max'] as int?,
      priceCurrency: json['price_currency'] as String? ?? 'IDR',
      priceNotes: json['price_notes'] as String? ?? '',
      targetAudience: json['target_audience'] as String? ?? '',
      extraDocs: (json['extra_docs'] as List?)?.map((e) => e.toString()).toList() ?? [],
      certificationType: json['certification_type'] as String? ?? '',
      minParticipants: json['min_participants'] as int?,
      maxParticipants: json['max_participants'] as int?,
      componentFailureConfig: failureConfig,
    );
  }

  // Konversi ke domain entity
  CourseTypeEntity toEntity() => CourseTypeEntity(
        id: id,
        masterCourseId: masterCourseId,
        typeName: typeName,
        isActive: isActive,
        priceType: priceType,
        priceMin: priceMin,
        priceMax: priceMax,
        priceCurrency: priceCurrency,
        priceNotes: priceNotes,
        targetAudience: targetAudience,
        extraDocs: extraDocs,
        certificationType: certificationType,
        minParticipants: minParticipants,
        maxParticipants: maxParticipants,
        componentFailureConfig: componentFailureConfig,
      );
}

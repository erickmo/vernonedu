import 'package:equatable/equatable.dart';

// Label untuk setiap nilai typeName
const _typeLabels = {
  'regular': 'Regular',
  'private': 'Private',
  'company_training': 'Company Training',
  'collab_university': 'Kolaborasi Universitas',
  'collab_school': 'Kolaborasi Sekolah',
  'program_karir': 'Program Karir',
};

// Entity domain untuk CourseType — satu master course bisa memiliki beberapa tipe
class CourseTypeEntity extends Equatable {
  final String id;
  final String masterCourseId;

  // Nilai valid: regular | private | company_training | collab_university | collab_school | program_karir
  final String typeName;

  final bool isActive;

  // Jenis harga: fixed | range | by_request
  final String priceType;
  final int? priceMin;
  final int? priceMax;
  final String priceCurrency;
  final String priceNotes;
  final String targetAudience;
  final List<String> extraDocs;
  final String certificationType;

  // Participant constraints
  final int? minParticipants;
  final int? maxParticipants;

  // Konfigurasi kegagalan komponen — opsional
  final Map<String, String>? componentFailureConfig;

  const CourseTypeEntity({
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

  // Label yang ditampilkan ke user berdasarkan typeName
  String get typeLabel => _typeLabels[typeName] ?? typeName;

  bool get isProgramKarir => typeName == 'program_karir';

  // Format tampilan harga berdasarkan priceType
  String get priceDisplay {
    if (priceType == 'by_request') return 'Hubungi Kami';
    final currency = priceCurrency.isEmpty ? 'IDR' : priceCurrency;
    if (priceType == 'fixed' && priceMin != null) {
      return '$currency ${_formatNumber(priceMin!)}';
    }
    if (priceType == 'range' && priceMin != null && priceMax != null) {
      return '$currency ${_formatNumber(priceMin!)} – ${_formatNumber(priceMax!)}';
    }
    return priceNotes.isNotEmpty ? priceNotes : '—';
  }

  String _formatNumber(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  List<Object?> get props => [id, typeName, isActive];
}

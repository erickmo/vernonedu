import '../../domain/entities/mou_entity.dart';

class MouModel {
  final String id;
  final String documentNumber;
  final String startDate;
  final String endDate;
  final String notes;

  const MouModel({
    required this.id,
    required this.documentNumber,
    required this.startDate,
    required this.endDate,
    required this.notes,
  });

  factory MouModel.fromJson(Map<String, dynamic> json) {
    return MouModel(
      id: json['id']?.toString() ?? '',
      documentNumber: json['document_number']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  MouEntity toEntity() {
    return MouEntity(
      id: id,
      documentNumber: documentNumber,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    );
  }
}

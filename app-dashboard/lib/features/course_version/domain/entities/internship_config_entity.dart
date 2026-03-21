import 'package:equatable/equatable.dart';

class InternshipConfigEntity extends Equatable {
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

  const InternshipConfigEntity({
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
  });

  bool get isEmpty => id.isEmpty;

  @override
  List<Object?> get props => [id, courseVersionId];
}

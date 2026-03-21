import 'package:equatable/equatable.dart';

class CrmLogEntity extends Equatable {
  final String id;
  final String leadId;
  final String contactedById;
  final String contactMethod; // phone, email, whatsapp
  final String response;
  final DateTime? followUpDate;
  final DateTime createdAt;

  const CrmLogEntity({
    required this.id,
    required this.leadId,
    required this.contactedById,
    required this.contactMethod,
    required this.response,
    this.followUpDate,
    required this.createdAt,
  });

  String get contactMethodLabel => switch (contactMethod) {
        'phone' => 'Telepon',
        'email' => 'Email',
        'whatsapp' => 'WhatsApp',
        _ => contactMethod,
      };

  @override
  List<Object?> get props => [id];
}

import 'package:equatable/equatable.dart';

class MouEntity extends Equatable {
  final String id;
  final String documentNumber;
  final String startDate;
  final String endDate;
  final String notes;

  const MouEntity({
    required this.id,
    required this.documentNumber,
    required this.startDate,
    required this.endDate,
    required this.notes,
  });

  bool get isExpiringSoon {
    try {
      final end = DateTime.parse(endDate);
      final diff = end.difference(DateTime.now()).inDays;
      return diff <= 90 && diff >= 0;
    } catch (_) {
      return false;
    }
  }

  @override
  List<Object?> get props => [id];
}

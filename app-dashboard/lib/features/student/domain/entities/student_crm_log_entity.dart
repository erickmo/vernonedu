import 'package:equatable/equatable.dart';

class StudentCrmLogEntity extends Equatable {
  final String id;
  final String studentId;
  final DateTime date;
  final String contactedBy;
  final String contactMethod;
  final String response;

  const StudentCrmLogEntity({
    required this.id,
    required this.studentId,
    required this.date,
    required this.contactedBy,
    required this.contactMethod,
    required this.response,
  });

  @override
  List<Object?> get props => [id];
}

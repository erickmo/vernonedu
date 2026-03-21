import 'package:equatable/equatable.dart';

/// Payment method options for a course batch.
enum BatchPaymentMethod {
  upfront,
  scheduled,
  monthly,
  batchLump,
  perSession;

  static BatchPaymentMethod fromString(String v) => switch (v.toLowerCase()) {
        'upfront' => BatchPaymentMethod.upfront,
        'scheduled' => BatchPaymentMethod.scheduled,
        'monthly' => BatchPaymentMethod.monthly,
        'batch_lump' || 'batchlump' => BatchPaymentMethod.batchLump,
        'per_session' || 'persession' => BatchPaymentMethod.perSession,
        _ => BatchPaymentMethod.upfront,
      };

  String get label => switch (this) {
        BatchPaymentMethod.upfront => 'Lunas di Awal',
        BatchPaymentMethod.scheduled => 'Cicilan Terjadwal',
        BatchPaymentMethod.monthly => 'Bulanan',
        BatchPaymentMethod.batchLump => 'Per Batch',
        BatchPaymentMethod.perSession => 'Per Sesi',
      };
}

class CourseBatchEntity extends Equatable {
  final String id;
  final String code;
  final String masterCourseId;
  final String masterCourseName;
  final String courseTypeId;
  final String courseTypeName;
  final String courseId;
  final String courseName;
  final DateTime startDate;
  final DateTime endDate;

  /// Status: upcoming | ongoing | completed | cancelled
  final String status;

  final String? facilitatorId;
  final String? facilitatorName;
  final int totalEnrolled;
  final int minParticipants;
  final int maxParticipants;

  /// Toggle: visible on public website. Op Leader can hide before batch is full.
  final bool websiteVisible;

  final double? price;
  final BatchPaymentMethod? paymentMethod;
  final bool isActive;

  const CourseBatchEntity({
    required this.id,
    required this.code,
    required this.masterCourseId,
    required this.masterCourseName,
    required this.courseTypeId,
    required this.courseTypeName,
    required this.courseId,
    required this.courseName,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.facilitatorId,
    this.facilitatorName,
    required this.totalEnrolled,
    required this.minParticipants,
    required this.maxParticipants,
    required this.websiteVisible,
    this.price,
    this.paymentMethod,
    required this.isActive,
  });

  double get fillRate =>
      maxParticipants == 0 ? 0 : totalEnrolled / maxParticipants;

  bool get isFull => maxParticipants > 0 && totalEnrolled >= maxParticipants;
  bool get isOngoing => status == 'ongoing';
  bool get isUpcoming => status == 'upcoming';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  int get durationDays => endDate.difference(startDate).inDays;

  String get statusLabel => switch (status) {
        'upcoming' => 'Akan Datang',
        'ongoing' => 'Berlangsung',
        'completed' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        _ => status,
      };

  @override
  List<Object?> get props => [id];
}

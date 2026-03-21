import 'package:equatable/equatable.dart';

class ReportFilterEntity extends Equatable {
  final String period; // 'monthly' | 'quarterly' | 'yearly' | 'custom'
  final String? branchId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportFilterEntity({
    this.period = 'monthly',
    this.branchId,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [period, branchId, fromDate, toDate];

  ReportFilterEntity copyWith({
    String? period,
    String? branchId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return ReportFilterEntity(
      period: period ?? this.period,
      branchId: branchId ?? this.branchId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'period': period};
    if (branchId != null && branchId!.isNotEmpty) params['branch_id'] = branchId;
    if (fromDate != null) {
      params['from_date'] = fromDate!.toIso8601String().split('T').first;
    }
    if (toDate != null) {
      params['to_date'] = toDate!.toIso8601String().split('T').first;
    }
    return params;
  }
}

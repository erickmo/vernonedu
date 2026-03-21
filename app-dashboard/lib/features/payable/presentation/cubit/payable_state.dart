import 'package:equatable/equatable.dart';

import '../../domain/entities/payable_entity.dart';

abstract class PayableState extends Equatable {
  const PayableState();

  @override
  List<Object?> get props => [];
}

class PayableInitial extends PayableState {
  const PayableInitial();
}

class PayableLoading extends PayableState {
  const PayableLoading();
}

class PayableLoaded extends PayableState {
  final PayableStatsEntity stats;
  final List<PayableEntity> payables;
  final int currentPage;
  final bool hasMore;
  final String? activeType;
  final String? activeStatus;

  const PayableLoaded({
    required this.stats,
    required this.payables,
    this.currentPage = 0,
    this.hasMore = true,
    this.activeType,
    this.activeStatus,
  });

  PayableLoaded copyWith({
    PayableStatsEntity? stats,
    List<PayableEntity>? payables,
    int? currentPage,
    bool? hasMore,
    String? activeType,
    String? activeStatus,
    bool clearType = false,
    bool clearStatus = false,
  }) =>
      PayableLoaded(
        stats: stats ?? this.stats,
        payables: payables ?? this.payables,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
        activeType: clearType ? null : (activeType ?? this.activeType),
        activeStatus:
            clearStatus ? null : (activeStatus ?? this.activeStatus),
      );

  @override
  List<Object?> get props => [
        stats,
        payables,
        currentPage,
        hasMore,
        activeType,
        activeStatus,
      ];
}

class PayableError extends PayableState {
  final String message;
  const PayableError(this.message);

  @override
  List<Object?> get props => [message];
}

class PayableActionSuccess extends PayableState {
  final String message;
  const PayableActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

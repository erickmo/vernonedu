import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_detail_entity.dart';
import '../../domain/entities/invoice_stats_entity.dart';

class InvoiceFilterState extends Equatable {
  final String invoiceNumber;
  final String studentName;
  final String status;
  final String batchId;
  final String paymentMethod;
  final String? fromDate;
  final String? toDate;

  const InvoiceFilterState({
    this.invoiceNumber = '',
    this.studentName = '',
    this.status = '',
    this.batchId = '',
    this.paymentMethod = '',
    this.fromDate,
    this.toDate,
  });

  InvoiceFilterState copyWith({
    String? invoiceNumber,
    String? studentName,
    String? status,
    String? batchId,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) =>
      InvoiceFilterState(
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        studentName: studentName ?? this.studentName,
        status: status ?? this.status,
        batchId: batchId ?? this.batchId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
        toDate: clearToDate ? null : (toDate ?? this.toDate),
      );

  @override
  List<Object?> get props => [
        invoiceNumber,
        studentName,
        status,
        batchId,
        paymentMethod,
        fromDate,
        toDate,
      ];
}

abstract class InvoiceState extends Equatable {
  const InvoiceState();
}

class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
  @override
  List<Object?> get props => [];
}

class InvoiceLoading extends InvoiceState {
  const InvoiceLoading();
  @override
  List<Object?> get props => [];
}

class InvoiceLoaded extends InvoiceState {
  final InvoiceStatsEntity stats;
  final List<InvoiceDetailEntity> invoices;
  final int currentPage;
  final bool hasMore;
  final InvoiceFilterState filter;

  const InvoiceLoaded({
    required this.stats,
    required this.invoices,
    this.currentPage = 0,
    this.hasMore = false,
    this.filter = const InvoiceFilterState(),
  });

  InvoiceLoaded copyWith({
    InvoiceStatsEntity? stats,
    List<InvoiceDetailEntity>? invoices,
    int? currentPage,
    bool? hasMore,
    InvoiceFilterState? filter,
  }) =>
      InvoiceLoaded(
        stats: stats ?? this.stats,
        invoices: invoices ?? this.invoices,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
        filter: filter ?? this.filter,
      );

  @override
  List<Object?> get props => [stats, invoices, currentPage, hasMore, filter];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoiceActionSuccess extends InvoiceState {
  final String message;
  final InvoiceLoaded previous;

  const InvoiceActionSuccess({
    required this.message,
    required this.previous,
  });

  @override
  List<Object?> get props => [message, previous];
}

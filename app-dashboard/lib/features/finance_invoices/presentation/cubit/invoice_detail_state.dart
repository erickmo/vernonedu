import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_detail_entity.dart';

abstract class InvoiceDetailState extends Equatable {
  const InvoiceDetailState();
}

class InvoiceDetailInitial extends InvoiceDetailState {
  const InvoiceDetailInitial();
  @override
  List<Object?> get props => [];
}

class InvoiceDetailLoading extends InvoiceDetailState {
  const InvoiceDetailLoading();
  @override
  List<Object?> get props => [];
}

class InvoiceDetailLoaded extends InvoiceDetailState {
  final InvoiceDetailEntity invoice;
  final String? actionMessage;

  const InvoiceDetailLoaded({required this.invoice, this.actionMessage});

  InvoiceDetailLoaded copyWith({
    InvoiceDetailEntity? invoice,
    String? actionMessage,
  }) =>
      InvoiceDetailLoaded(
        invoice: invoice ?? this.invoice,
        actionMessage: actionMessage,
      );

  @override
  List<Object?> get props => [invoice, actionMessage];
}

class InvoiceDetailError extends InvoiceDetailState {
  final String message;
  const InvoiceDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

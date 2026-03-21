part of 'certificate_cubit.dart';

abstract class CertificateState extends Equatable {
  const CertificateState();

  @override
  List<Object?> get props => [];
}

class CertificateInitial extends CertificateState {
  const CertificateInitial();
}

class CertificateLoading extends CertificateState {
  const CertificateLoading();
}

class CertificateLoaded extends CertificateState {
  final List<CertificateEntity> certificates;
  final List<CertificateTemplateEntity> templates;

  const CertificateLoaded({
    required this.certificates,
    required this.templates,
  });

  @override
  List<Object?> get props => [certificates, templates];
}

class CertificateError extends CertificateState {
  final String message;
  const CertificateError(this.message);

  @override
  List<Object?> get props => [message];
}

part of 'certificate_template_cubit.dart';

abstract class CertificateTemplateState extends Equatable {
  const CertificateTemplateState();

  @override
  List<Object?> get props => [];
}

class CertificateTemplateInitial extends CertificateTemplateState {
  const CertificateTemplateInitial();
}

class CertificateTemplateLoading extends CertificateTemplateState {
  const CertificateTemplateLoading();
}

class CertificateTemplateLoaded extends CertificateTemplateState {
  final List<CertificateTemplateEntity> templates;
  const CertificateTemplateLoaded(this.templates);

  @override
  List<Object?> get props => [templates];
}

class CertificateTemplateError extends CertificateTemplateState {
  final String message;
  const CertificateTemplateError(this.message);

  @override
  List<Object?> get props => [message];
}

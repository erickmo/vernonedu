import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../../domain/usecases/get_certificates_usecase.dart';
import '../../domain/usecases/get_certificate_templates_usecase.dart';
import '../../domain/usecases/issue_certificate_usecase.dart';
import '../../domain/usecases/revoke_certificate_usecase.dart';
import '../../domain/usecases/create_certificate_template_usecase.dart';

part 'certificate_state.dart';

class CertificateCubit extends Cubit<CertificateState> {
  final GetCertificatesUseCase _getCertificates;
  final GetCertificateTemplatesUseCase _getTemplates;
  final IssueCertificateUseCase _issueCertificate;
  final RevokeCertificateUseCase _revokeCertificate;
  final CreateCertificateTemplateUseCase _createTemplate;

  CertificateCubit({
    required GetCertificatesUseCase getCertificatesUseCase,
    required GetCertificateTemplatesUseCase getTemplatesUseCase,
    required IssueCertificateUseCase issueCertificateUseCase,
    required RevokeCertificateUseCase revokeCertificateUseCase,
    required CreateCertificateTemplateUseCase createTemplateUseCase,
  })  : _getCertificates = getCertificatesUseCase,
        _getTemplates = getTemplatesUseCase,
        _issueCertificate = issueCertificateUseCase,
        _revokeCertificate = revokeCertificateUseCase,
        _createTemplate = createTemplateUseCase,
        super(const CertificateInitial());

  Future<void> loadAll({
    String? statusFilter,
    String? typeFilter,
  }) async {
    emit(const CertificateLoading());

    final results = await Future.wait([
      _getCertificates(
        status: statusFilter,
        type: typeFilter,
        limit: 100,
      ),
      _getTemplates(),
    ]);

    final certsResult = results[0];
    final certs = certsResult.fold(
      (f) => <CertificateEntity>[],
      (d) => d as List<CertificateEntity>,
    );

    final templatesResult = results[1];
    final templates = templatesResult.fold(
      (f) => <CertificateTemplateEntity>[],
      (d) => d as List<CertificateTemplateEntity>,
    );

    emit(CertificateLoaded(certificates: certs, templates: templates));
  }

  Future<bool> issueCertificate({required Map<String, dynamic> body}) async {
    final result = await _issueCertificate(body: body);
    return result.fold(
      (failure) {
        emit(CertificateError(failure.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> revokeCertificate({
    required String id,
    required String reason,
  }) async {
    final result = await _revokeCertificate(id: id, reason: reason);
    return result.fold(
      (failure) {
        emit(CertificateError(failure.message));
        return false;
      },
      (_) {
        if (state is CertificateLoaded) {
          final s = state as CertificateLoaded;
          final updated = s.certificates
              .map((c) => c.id == id
                  ? CertificateEntity(
                      id: c.id,
                      templateId: c.templateId,
                      studentId: c.studentId,
                      batchId: c.batchId,
                      courseId: c.courseId,
                      type: c.type,
                      certificateCode: c.certificateCode,
                      qrCodeUrl: c.qrCodeUrl,
                      status: 'revoked',
                      issuedAt: c.issuedAt,
                      revokedAt: DateTime.now(),
                      revocationReason: reason,
                      studentName: c.studentName,
                      courseName: c.courseName,
                      batchName: c.batchName,
                    )
                  : c)
              .toList();
          emit(CertificateLoaded(
            certificates: updated,
            templates: s.templates,
          ));
        }
        return true;
      },
    );
  }

  Future<bool> createTemplate({required Map<String, dynamic> body}) async {
    final result = await _createTemplate(body: body);
    return result.fold(
      (failure) {
        emit(CertificateError(failure.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }
}

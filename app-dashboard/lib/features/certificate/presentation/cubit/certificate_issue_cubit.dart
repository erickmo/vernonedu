import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/issue_competency_certificate_usecase.dart';
import '../../domain/usecases/issue_participant_certificate_usecase.dart';

abstract class CertificateIssueState extends Equatable {
  const CertificateIssueState();
  @override
  List<Object?> get props => [];
}

class CertificateIssueInitial extends CertificateIssueState {
  const CertificateIssueInitial();
}

class CertificateIssueLoading extends CertificateIssueState {
  const CertificateIssueLoading();
}

class CertificateIssueSuccess extends CertificateIssueState {
  final String message;
  final int issuedCount;
  const CertificateIssueSuccess({
    required this.message,
    this.issuedCount = 1,
  });
  @override
  List<Object?> get props => [message, issuedCount];
}

class CertificateIssueError extends CertificateIssueState {
  final String message;
  const CertificateIssueError(this.message);
  @override
  List<Object?> get props => [message];
}

class CertificateIssueCubit extends Cubit<CertificateIssueState> {
  final IssueParticipantCertificateUseCase _issueParticipant;
  final IssueCompetencyCertificateUseCase _issueCompetency;

  CertificateIssueCubit({
    required IssueParticipantCertificateUseCase issueParticipant,
    required IssueCompetencyCertificateUseCase issueCompetency,
  })  : _issueParticipant = issueParticipant,
        _issueCompetency = issueCompetency,
        super(const CertificateIssueInitial());

  Future<void> issueParticipant({
    required String batchId,
    required List<String> studentIds,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  }) async {
    emit(const CertificateIssueLoading());
    final result = await _issueParticipant(
      batchId: batchId,
      studentIds: studentIds,
      courseId: courseId,
      templateId: templateId,
      verificationBaseUrl: verificationBaseUrl,
    );
    result.fold(
      (f) => emit(CertificateIssueError(f.message)),
      (count) => emit(CertificateIssueSuccess(
        message: 'Berhasil menerbitkan $count sertifikat partisipan',
        issuedCount: count,
      )),
    );
  }

  Future<void> issueCompetency({
    required String studentId,
    required String courseId,
    String? batchId,
    String? templateId,
    bool testPassed = true,
    String? verificationBaseUrl,
  }) async {
    emit(const CertificateIssueLoading());
    final result = await _issueCompetency(
      studentId: studentId,
      courseId: courseId,
      batchId: batchId,
      templateId: templateId,
      testPassed: testPassed,
      verificationBaseUrl: verificationBaseUrl,
    );
    result.fold(
      (f) => emit(CertificateIssueError(f.message)),
      (_) => emit(const CertificateIssueSuccess(
        message: 'Sertifikat kompetensi berhasil diterbitkan',
      )),
    );
  }

  void reset() => emit(const CertificateIssueInitial());
}

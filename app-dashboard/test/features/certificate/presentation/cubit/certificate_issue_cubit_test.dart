import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/issue_competency_certificate_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/issue_participant_certificate_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/certificate_issue_cubit.dart';

class _MockParticipant extends Mock
    implements IssueParticipantCertificateUseCase {}

class _MockCompetency extends Mock implements IssueCompetencyCertificateUseCase {}

void main() {
  late _MockParticipant participant;
  late _MockCompetency competency;

  setUp(() {
    participant = _MockParticipant();
    competency = _MockCompetency();
  });

  blocTest<CertificateIssueCubit, CertificateIssueState>(
    'issueParticipant emits [Loading, Success] with count',
    build: () {
      when(() => participant(
            batchId: any(named: 'batchId'),
            studentIds: any(named: 'studentIds'),
            courseId: any(named: 'courseId'),
            templateId: any(named: 'templateId'),
            verificationBaseUrl: any(named: 'verificationBaseUrl'),
          )).thenAnswer((_) async => const Right(2));
      return CertificateIssueCubit(
        issueParticipant: participant,
        issueCompetency: competency,
      );
    },
    act: (c) => c.issueParticipant(
      batchId: 'b1',
      studentIds: ['s1', 's2'],
      courseId: 'c1',
    ),
    expect: () => [
      const CertificateIssueLoading(),
      isA<CertificateIssueSuccess>()
          .having((s) => s.issuedCount, 'issuedCount', 2),
    ],
  );

  blocTest<CertificateIssueCubit, CertificateIssueState>(
    'issueParticipant emits [Loading, Error] on failure',
    build: () {
      when(() => participant(
            batchId: any(named: 'batchId'),
            studentIds: any(named: 'studentIds'),
            courseId: any(named: 'courseId'),
            templateId: any(named: 'templateId'),
            verificationBaseUrl: any(named: 'verificationBaseUrl'),
          )).thenAnswer((_) async => const Left(ServerFailure('nope')));
      return CertificateIssueCubit(
        issueParticipant: participant,
        issueCompetency: competency,
      );
    },
    act: (c) => c.issueParticipant(
      batchId: 'b1',
      studentIds: ['s1'],
      courseId: 'c1',
    ),
    expect: () => [
      const CertificateIssueLoading(),
      const CertificateIssueError('nope'),
    ],
  );
}

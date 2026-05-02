import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/repositories/certificate_repository.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/issue_competency_certificate_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/issue_participant_certificate_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/list_certificates_by_batch_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/list_certificates_by_student_usecase.dart';

class _MockRepo extends Mock implements CertificateRepository {}

CertificateEntity _entity(String id) => CertificateEntity(
      id: id,
      studentId: 'stu',
      courseId: 'crs',
      type: 'participant',
      certificateCode: 'VE-P-2026-X',
      qrCodeUrl: 'https://x',
      status: 'active',
      issuedAt: DateTime(2026, 5, 1),
    );

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  test('IssueParticipantCertificateUseCase delegates to repo and returns count',
      () async {
    when(() => repo.issueParticipantBulk(
          batchId: any(named: 'batchId'),
          studentIds: any(named: 'studentIds'),
          courseId: any(named: 'courseId'),
          templateId: any(named: 'templateId'),
          verificationBaseUrl: any(named: 'verificationBaseUrl'),
        )).thenAnswer((_) async => const Right(2));

    final usecase = IssueParticipantCertificateUseCase(repo);
    final result = await usecase(
      batchId: 'b1',
      studentIds: ['s1', 's2'],
      courseId: 'c1',
    );

    expect(result, equals(const Right<Failure, int>(2)));
  });

  test('IssueCompetencyCertificateUseCase passes testPassed=true by default',
      () async {
    when(() => repo.issueCompetency(
          studentId: any(named: 'studentId'),
          courseId: any(named: 'courseId'),
          batchId: any(named: 'batchId'),
          templateId: any(named: 'templateId'),
          testPassed: any(named: 'testPassed'),
          verificationBaseUrl: any(named: 'verificationBaseUrl'),
        )).thenAnswer((_) async => const Right(null));

    final usecase = IssueCompetencyCertificateUseCase(repo);
    final result =
        await usecase(studentId: 's1', courseId: 'c1', batchId: 'b1');

    expect(result.isRight(), isTrue);
    verify(() => repo.issueCompetency(
          studentId: 's1',
          courseId: 'c1',
          batchId: 'b1',
          templateId: null,
          testPassed: true,
          verificationBaseUrl: null,
        )).called(1);
  });

  test('ListCertificatesByStudentUseCase returns entities', () async {
    when(() => repo.listByStudent('stu-1'))
        .thenAnswer((_) async => Right([_entity('a')]));

    final result = await ListCertificatesByStudentUseCase(repo)('stu-1');
    result.fold((_) => fail('expected Right'),
        (items) => expect(items.first.id, 'a'));
  });

  test('ListCertificatesByBatchUseCase returns entities', () async {
    when(() => repo.listByBatch('b-1'))
        .thenAnswer((_) async => Right([_entity('a'), _entity('b')]));

    final result = await ListCertificatesByBatchUseCase(repo)('b-1');
    result.fold(
        (_) => fail('expected Right'), (items) => expect(items, hasLength(2)));
  });
}

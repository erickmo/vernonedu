import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/core/network/network_info.dart';
import 'package:vernonedu_dashboard/features/certificate/data/datasources/certificate_remote_datasource.dart';
import 'package:vernonedu_dashboard/features/certificate/data/models/certificate_model.dart';
import 'package:vernonedu_dashboard/features/certificate/data/repositories/certificate_repository_impl.dart';

class _MockDs extends Mock implements CertificateRemoteDataSource {}

class _MockNet extends Mock implements NetworkInfo {}

CertificateModel _model(String id) => CertificateModel(
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
  late _MockDs ds;
  late _MockNet net;
  late CertificateRepositoryImpl repo;

  setUp(() {
    ds = _MockDs();
    net = _MockNet();
    repo = CertificateRepositoryImpl(remoteDataSource: ds, networkInfo: net);
    when(() => net.isConnected).thenAnswer((_) async => true);
  });

  group('issueParticipantBulk', () {
    test('issues for each studentId and returns count on success', () async {
      when(() => ds.issueParticipantSingle(
            batchId: any(named: 'batchId'),
            studentId: any(named: 'studentId'),
            courseId: any(named: 'courseId'),
            templateId: any(named: 'templateId'),
            verificationBaseUrl: any(named: 'verificationBaseUrl'),
          )).thenAnswer((_) async {});

      final result = await repo.issueParticipantBulk(
        batchId: 'b1',
        studentIds: ['s1', 's2', 's3'],
        courseId: 'c1',
      );

      expect(result, equals(const Right<Failure, int>(3)));
      verify(() => ds.issueParticipantSingle(
            batchId: 'b1',
            studentId: 's1',
            courseId: 'c1',
            templateId: null,
            verificationBaseUrl: null,
          )).called(1);
      verify(() => ds.issueParticipantSingle(
            batchId: 'b1',
            studentId: 's2',
            courseId: 'c1',
            templateId: null,
            verificationBaseUrl: null,
          )).called(1);
    });

    test('returns ServerFailure when DioException is thrown', () async {
      when(() => ds.issueParticipantSingle(
            batchId: any(named: 'batchId'),
            studentId: any(named: 'studentId'),
            courseId: any(named: 'courseId'),
            templateId: any(named: 'templateId'),
            verificationBaseUrl: any(named: 'verificationBaseUrl'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/x'),
        message: 'boom',
      ));

      final result = await repo.issueParticipantBulk(
        batchId: 'b1',
        studentIds: ['s1'],
        courseId: 'c1',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns NetworkFailure when offline', () async {
      when(() => net.isConnected).thenAnswer((_) async => false);

      final result = await repo.issueParticipantBulk(
        batchId: 'b1',
        studentIds: ['s1'],
        courseId: 'c1',
      );

      expect(result, equals(const Left<Failure, int>(NetworkFailure())));
      verifyNever(() => ds.issueParticipantSingle(
            batchId: any(named: 'batchId'),
            studentId: any(named: 'studentId'),
            courseId: any(named: 'courseId'),
          ));
    });
  });

  group('listByStudent', () {
    test('returns mapped entities on success', () async {
      when(() => ds.listByStudent('stu-1'))
          .thenAnswer((_) async => [_model('a'), _model('b')]);

      final result = await repo.listByStudent('stu-1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (items) {
        expect(items, hasLength(2));
        expect(items.first.id, 'a');
      });
    });

    test('maps DioException to ServerFailure', () async {
      when(() => ds.listByStudent('stu-1')).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/x'),
        message: 'down',
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
          data: {'error': 'down'},
        ),
      ));

      final result = await repo.listByStudent('stu-1');

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'down');
        },
        (_) => fail('expected Left'),
      );
    });
  });
}

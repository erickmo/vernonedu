import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_website/core/services/public_certificate_service.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late PublicCertificateService service;

  setUp(() {
    dio = _MockDio();
    service = PublicCertificateService(dio: dio);
  });

  Response<dynamic> resp(int status, {Object? data}) => Response<dynamic>(
        requestOptions: RequestOptions(path: ''),
        statusCode: status,
        data: data,
      );

  test('200 returns parsed model', () async {
    when(() => dio.get(any())).thenAnswer((_) async => resp(200, data: {
          'certificate_code': 'OK1',
          'type': 'participant',
          'issued_at': '2026-04-01T10:00:00Z',
          'status': 'active',
          'is_valid': true,
          'is_revoked': false,
        }));

    final cert = await service.verifyCertificate('OK1');

    expect(cert.code, 'OK1');
    expect(cert.isValid, true);
    verify(() => dio.get('/public/certificates/verify/OK1')).called(1);
  });

  test('404 throws CertificateNotFoundException', () async {
    when(() => dio.get(any())).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      response: resp(404),
      type: DioExceptionType.badResponse,
    ));

    expect(
      () => service.verifyCertificate('MISSING'),
      throwsA(isA<CertificateNotFoundException>()),
    );
  });

  test('500 rethrows DioException', () async {
    when(() => dio.get(any())).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      response: resp(500),
      type: DioExceptionType.badResponse,
    ));

    expect(
      () => service.verifyCertificate('BOOM'),
      throwsA(isA<DioException>()),
    );
  });
}

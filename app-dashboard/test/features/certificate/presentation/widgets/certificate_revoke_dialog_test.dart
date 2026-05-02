import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/widgets/certificate_revoke_dialog.dart';

CertificateEntity _cert() => CertificateEntity(
      id: 'c1',
      studentId: 'stu-1',
      courseId: 'crs-1',
      type: 'participant',
      certificateCode: 'VE-P-2026-XYZ',
      qrCodeUrl: 'https://x',
      status: 'active',
      issuedAt: DateTime(2026, 5, 1),
      studentName: 'Budi',
      courseName: 'Bahasa',
    );

Future<String?> _open(WidgetTester tester) async {
  String? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (ctx) {
      return Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            result = await showCertificateRevokeDialog(ctx,
                certificate: _cert());
          },
          child: const Text('open'),
        ),
      );
    }),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('dialog shows with cert metadata', (tester) async {
    await _open(tester);
    expect(find.text('Cabut Sertifikat'), findsOneWidget);
    expect(find.text('VE-P-2026-XYZ'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.textContaining('Dept Leader'), findsOneWidget);
  });

  testWidgets('submit disabled when reason < 20 chars', (tester) async {
    await _open(tester);
    // Initially disabled.
    final btnFinder = find.byKey(const Key('revoke_submit_button'));
    var btn = tester.widget<FilledButton>(btnFinder);
    expect(btn.onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('revoke_reason_field')), 'short');
    await tester.pump();
    btn = tester.widget<FilledButton>(btnFinder);
    expect(btn.onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('revoke_reason_field')),
        'Alasan pencabutan resmi panjang');
    await tester.pump();
    btn = tester.widget<FilledButton>(btnFinder);
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('submit returns reason on tap', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await showCertificateRevokeDialog(ctx,
                  certificate: _cert());
            },
            child: const Text('open'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    const reason = 'Sertifikat diterbitkan keliru';
    await tester.enterText(
        find.byKey(const Key('revoke_reason_field')), reason);
    await tester.pump();
    await tester.tap(find.byKey(const Key('revoke_submit_button')));
    await tester.pumpAndSettle();

    expect(result, reason);
  });
}

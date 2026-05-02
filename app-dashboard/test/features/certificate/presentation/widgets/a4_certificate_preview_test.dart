import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_template_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/widgets/a4_certificate_preview.dart';

void main() {
  CertificateTemplateEntity defaultTemplate() => CertificateTemplateEntity(
        id: 't1',
        name: 'Default',
        type: 'participant',
        title: 'Sertifikat',
        bodyText: 'Diberikan kepada peserta',
        signatureBlocks: const [
          SignatureBlockEntity(
              name: 'Direktur', role: 'Director', x: 0.5, y: 0.8),
        ],
        createdAt: DateTime(2026, 1, 1),
      );

  testWidgets('A4 preview shows title, body, and signature', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          child: A4CertificatePreview(config: defaultTemplate()),
        ),
      ),
    ));

    expect(find.text('Sertifikat'), findsOneWidget);
    expect(find.text('Diberikan kepada peserta'), findsOneWidget);
    expect(find.text('Direktur'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
  });

  testWidgets('A4 preview hides QR when qrPosition=none', (tester) async {
    final template = defaultTemplate().copyWith(qrPosition: 'none');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          child: A4CertificatePreview(config: template),
        ),
      ),
    ));

    expect(find.byIcon(Icons.qr_code_2), findsNothing);
  });

  testWidgets('A4 preview maintains 595/842 aspect ratio', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 595,
          child: A4CertificatePreview(config: defaultTemplate()),
        ),
      ),
    ));

    final aspect =
        tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio;
    expect(aspect, closeTo(595 / 842, 0.0001));
  });
}

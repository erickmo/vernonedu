import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/widgets/certificate_list_view.dart';

CertificateEntity _make({
  required String id,
  required String code,
  String type = 'participant',
  String status = 'active',
}) =>
    CertificateEntity(
      id: id,
      studentId: 'stu-$id',
      courseId: 'crs',
      type: type,
      certificateCode: code,
      qrCodeUrl: 'https://x',
      status: status,
      issuedAt: DateTime(2026, 5, 1),
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<CertificateEntity> items,
  required void Function(CertificateEntity) onRevoke,
  required void Function(CertificateEntity) onView,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CertificateListView(
          items: items,
          onRevoke: onRevoke,
          onView: onView,
        ),
      ),
    ),
  ));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('renders rows with code/type/status', (tester) async {
    final items = [
      _make(id: '1', code: 'VE-P-001'),
      _make(id: '2', code: 'VE-C-002', type: 'competency'),
    ];
    await _pump(tester, items: items, onRevoke: (_) {}, onView: (_) {});
    expect(find.text('VE-P-001'), findsOneWidget);
    expect(find.text('VE-C-002'), findsOneWidget);
    expect(find.text('Aktif'), findsNWidgets(2));
    expect(find.text('Partisipan'), findsOneWidget);
    expect(find.text('Kompetensi'), findsOneWidget);
  });

  testWidgets('revoke button hidden/disabled when status=revoked',
      (tester) async {
    final items = [_make(id: '1', code: 'VE-P-001', status: 'revoked')];
    var revoked = false;
    await _pump(
      tester,
      items: items,
      onRevoke: (_) => revoked = true,
      onView: (_) {},
    );
    expect(find.text('Dicabut'), findsOneWidget);
    final blockBtn = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.block),
        matching: find.byType(IconButton),
      ),
    );
    expect(blockBtn.onPressed, isNull);
    // Tapping should not invoke the callback.
    await tester.tap(find.byIcon(Icons.block), warnIfMissed: false);
    await tester.pump();
    expect(revoked, isFalse);
  });

  testWidgets('tapping revoke calls onRevoke', (tester) async {
    final items = [_make(id: '1', code: 'VE-P-001')];
    CertificateEntity? captured;
    await _pump(
      tester,
      items: items,
      onRevoke: (c) => captured = c,
      onView: (_) {},
    );
    await tester.tap(find.byIcon(Icons.block));
    await tester.pump();
    expect(captured?.id, '1');
  });
}

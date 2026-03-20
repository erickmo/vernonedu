import 'package:flutter_test/flutter_test.dart';

import 'package:vernonedu_entrepreneurship_app/main.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('VernonEdu Entrepreneurship'), findsOneWidget);
  });
}

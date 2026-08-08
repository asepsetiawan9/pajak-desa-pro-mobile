import 'package:flutter_test/flutter_test.dart';
import 'package:pajak_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PajakMobileApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(PajakMobileApp), findsOneWidget);
  });
}

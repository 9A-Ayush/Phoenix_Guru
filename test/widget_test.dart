import 'package:flutter_test/flutter_test.dart';
import 'package:phoenix_guru/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PhoenixGuruApp());
    expect(find.byType(PhoenixGuruApp), findsOneWidget);
  });
}

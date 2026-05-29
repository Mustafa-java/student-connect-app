import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_connect/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StudentConnectApp(),
      ),
    );

    // Проверяем что splash screen отображается
    expect(find.text('СтудХаб'), findsOneWidget);
  });
}

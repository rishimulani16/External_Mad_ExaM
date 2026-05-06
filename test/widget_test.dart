import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_queue_app/main.dart';

void main() {
  testWidgets('App smoke test — root widget renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AppointQApp()),
    );
    expect(find.text('AppointQ'), findsOneWidget);
  });
}

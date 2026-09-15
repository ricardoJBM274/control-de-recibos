// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:receipt_scanner/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp()); // Build our app

    // Verify that the dashboard is displayed as the initial screen.
    expect(find.text('\$450.25'), findsOneWidget);
    expect(find.text('Gasto total este mes'), findsOneWidget);
    expect(find.text('Actividad reciente'), findsOneWidget);


    // Additional assertions can be added here if needed.
  });
}

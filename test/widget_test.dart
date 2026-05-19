// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sapo_clone_app/main.dart';

void main() {
  testWidgets('Sapo Clone app initializes without crashing', (WidgetTester tester) async {
    // Build the Sapo Clone app
    await tester.pumpWidget(const MyApp());
    
    // Give the app time to load
    await tester.pumpAndSettle();
    
    // Verify the app built successfully (no exceptions thrown)
    expect(find.byType(MyApp), findsOneWidget);
  });
}

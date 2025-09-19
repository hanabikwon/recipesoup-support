// This is a basic Flutter widget test for Recipesoup app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:recipesoup/main.dart';

void main() {
  setUpAll(() async {
    // Hive 초기화 (테스트용)
    await Hive.initFlutter();
  });

  testWidgets('Recipesoup app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RecipesoupApp());
    
    // Allow for splash screen and initialization
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that the app loads without crashing
    // The exact widgets will depend on the current implementation
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

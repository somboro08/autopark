import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autopark_mvp/main.dart';

void main() {
  testWidgets('AutoPark app launches and reaches home', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoParkApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash timer (2s) fire and navigate to the home screen.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    // The home screen bottom navigation should be visible.
    expect(find.text('Retrouver un auto'), findsWidgets);
    expect(find.text('Enregistrer un auto'), findsWidgets);
  });
}

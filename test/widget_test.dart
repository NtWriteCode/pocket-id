import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_id/main.dart';

void main() {
  testWidgets('App starts with home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PocketIdApp());

    // Verify that the app title is displayed
    expect(find.text('Pocket ID'), findsOneWidget);
  });
}

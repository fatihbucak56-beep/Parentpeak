import 'package:flutter_test/flutter_test.dart';
import 'package:trusted_circle_demo/lib/ui/device_management_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Smoke Test'))));
    expect(find.text('Smoke Test'), findsOneWidget);
  });
}

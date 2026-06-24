import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trusted_circle_demo/ui/create_event_screen.dart';

void main() {
  testWidgets('CreateEventScreen shows photo section controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateEventScreen(),
      ),
    );

    // CreateEventScreen triggers an async contacts load with a short timer.
    // Advance fake time once so no pending timer remains at test teardown.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Event-Foto (optional)'), findsOneWidget);
    expect(find.text('Foto auswählen'), findsOneWidget);
    expect(find.text('Entfernen'), findsNothing);
  });
}

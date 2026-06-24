import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/ui/payment_screen.dart';

MeetupEvent _buildEvent() {
  return MeetupEvent(
    id: 'evt_1',
    hosterId: 'user_1',
    title: 'Test Event',
    description: 'Beschreibung',
    category: EventCategory.socialGathering,
    ageGroups: const [AgeGroup.mixed],
    location: 'Berlin',
    latitude: 52.52,
    longitude: 13.405,
    eventDate: DateTime.now().add(const Duration(days: 1)),
    createdAt: DateTime.now(),
    maxParticipants: 10,
    photoUrl: '',
  );
}

void main() {
  testWidgets('PaymentScreen warns when Stripe key is missing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentScreen(
          event: _buildEvent(),
          amount: 9.99,
        ),
      ),
    );

    await tester.pumpAndSettle();

  final termsText = find.text('Bedingungen akzeptieren');
  await tester.ensureVisible(termsText);
  await tester.tap(termsText);
    await tester.pumpAndSettle();

  final payButton = find.text('Jetzt 9.99 € zahlen');
  await tester.ensureVisible(payButton);
  await tester.tap(payButton);
    await tester.pump();

    expect(
      find.text(
        'Stripe ist aktuell nicht konfiguriert. Bitte waehle PayPal oder kontaktiere den Support.',
      ),
      findsOneWidget,
    );
  });
}

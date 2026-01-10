import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';
import 'package:trusted_circle_demo/ui/revoke_confirmation_dialog.dart';

void main() {
  testWidgets('Revoke dialog enables confirm only on exact name', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return ElevatedButton(
          child: const Text('Open'),
          onPressed: () => showDialog<bool>(context: context, builder: (_) => const RevokeConfirmationDialog(deviceName: 'MyDevice')),
        );
      }),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Gerätename eingeben'), findsOneWidget);

    // Confirm button should be disabled initially
    final confirmButton = find.byKey(const Key('confirm-revoke'));
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);

    // Enter wrong name
    await tester.enterText(find.byType(TextField), 'Wrong');
    await tester.pumpAndSettle();
    expect(find.text('Der eingegebene Name stimmt nicht überein.'), findsOneWidget);

    // Enter correct name
    await tester.enterText(find.byType(TextField), 'MyDevice');
    await tester.pumpAndSettle();

    // Confirm button enabled
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);
  });
}

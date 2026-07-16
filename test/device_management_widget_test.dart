import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parentpeak/l10n/app_localizations.dart';
import 'package:parentpeak/models/trusted_device.dart';
import 'package:parentpeak/ui/device_management_screen.dart';

void main() {
  testWidgets('DeviceManagementScreen revoke flow success', (WidgetTester tester) async {
    final device = TrustedDevice(deviceUuid: 'uuid-1', deviceName: 'TestDevice', status: DeviceStatus.active);
    late String revokedUuid;

    Future<bool> fakeRevoke(String uuid, String name) async {
      revokedUuid = uuid;
      return true;
    }

    await tester.pumpWidget(MaterialApp(
      home: DeviceManagementScreen(devices: [device], onRevoke: fakeRevoke),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],      locale: const Locale('de'),      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    final loc = AppLocalizations(const Locale('de'));

    // Tap revoke button
    final listButton = find.byKey(const Key('revoke-uuid-1'));
    expect(listButton, findsOneWidget);
    await tester.tap(listButton);
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text(loc.removeDeviceDialogTitle), findsOneWidget);

    // Enter correct device name
    await tester.enterText(find.byType(TextField), 'TestDevice');
    await tester.pumpAndSettle();

    // Confirm
    final confirmButton = find.byKey(const Key('confirm-revoke'));
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(revokedUuid, equals('uuid-1'));
    // After success message (snackbar) appears
    expect(find.text(loc.deviceRemoved), findsOneWidget);
  });
}

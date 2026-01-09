import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'lib/logic/revocation_service.dart';
import 'lib/logic/background_sync_manager.dart';
import 'lib/models/trusted_device.dart';
import 'lib/ui/device_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundSyncManager.initialize();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RevocationService(baseUrl: 'https://api.example.com');

    final mockDevices = [
      TrustedDevice(deviceUuid: 'uuid-1', deviceName: 'Mamas iPhone', status: DeviceStatus.active),
      TrustedDevice(deviceUuid: 'uuid-2', deviceName: 'Papas Pixel', status: DeviceStatus.active),
      TrustedDevice(deviceUuid: 'fail-uuid', deviceName: 'Test Fail Device', status: DeviceStatus.active),
      TrustedDevice(deviceUuid: 'uuid-removed', deviceName: 'Altes iPad', status: DeviceStatus.revoked, revokedAt: DateTime.now().subtract(const Duration(days: 3))),
    ];

    return MaterialApp(
      title: 'Parentpeak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de')],
      home: DeviceManagementScreen(
        devices: mockDevices,
        onRevoke: (uuid, name) async => await service.revokeDevice(uuid, 'Demo Revoke'),
      ),
    );
  }
}

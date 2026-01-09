import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trusted_circle_demo/logic/revocation_service_impl.dart';
import 'package:trusted_circle_demo/logic/secure_storage.dart';
import 'package:trusted_circle_demo/logic/background_sync_manager.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/device_management_screen.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundSyncManager.initialize();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = const FlutterSecureStorageAdapter();
    // For demo purpose only: write a fake token so the production-style revocation
    // implementation can read it from secure storage. DO NOT use real tokens here.
    storage.write(key: 'ABACUS_API_TOKEN', value: 'demo-token');
    final service = RevocationServiceImpl(baseUrl: 'https://api.example.com', secureStorage: storage);

    final mockDevices = [
      TrustedDevice(deviceUuid: 'uuid-1', deviceName: 'Mamas iPhone', status: DeviceStatus.active),
      TrustedDevice(deviceUuid: 'uuid-2', deviceName: 'Papas Pixel', status: DeviceStatus.active),
      TrustedDevice(deviceUuid: 'fail-uuid', deviceName: 'Test Fail Device', status: DeviceStatus.active),
      TrustedDevice(deviceUuid: 'uuid-removed', deviceName: 'Altes iPad', status: DeviceStatus.revoked, revokedAt: DateTime.now().subtract(const Duration(days: 3))),
    ];

    return MaterialApp(
      title: AppLocalizations.of(context)?.appTitle ?? 'Parentpeak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: DeviceManagementScreen(
        devices: mockDevices,
        onRevoke: (uuid, name) async {
          try {
            return await service.revokeDevice(uuid, 'Demo Revoke');
          } catch (e) {
            // For the demo surface failure as false and let UI show snackbar
            return false;
          }
        },
      ),
    );
  }
}

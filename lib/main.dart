import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trusted_circle_demo/logic/revocation_service_impl.dart';
import 'package:trusted_circle_demo/logic/secure_storage.dart';
import 'package:trusted_circle_demo/logic/background_sync_manager.dart';
import 'package:trusted_circle_demo/logic/notification_service.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/home_screen.dart';
import 'package:trusted_circle_demo/ui/chat_screen.dart';
import 'package:trusted_circle_demo/ui/family_profile_screen.dart';
import 'package:trusted_circle_demo/logic/theme_service.dart';
import 'package:trusted_circle_demo/logic/language_service.dart';
import 'package:trusted_circle_demo/widgets/language_aware_widget.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';
import 'package:trusted_circle_demo/widgets/language_provider.dart';

// Global service instances
final themeService = ThemeService();
final languageService = LanguageService();

// Global key for DemoApp state access
final GlobalKey<_DemoAppState> demoAppKey = GlobalKey<_DemoAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    print('Warnung: .env konnte nicht geladen werden: $e');
  }
  await BackgroundSyncManager.initialize();
  await NotificationService.instance.initialize();
  runApp(DemoApp(key: demoAppKey));
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  static void setThemeMode(ThemeMode mode) {
    print('📱 DemoApp.setThemeMode() called with mode=$mode');
    final state = demoAppKey.currentState;
    if (state == null) {
      print('❌ ERROR: DemoApp state not found via GlobalKey!');
      return;
    }
    state._setThemeMode(mode);
    print('   setState() called, rebuilding with themeMode=$mode');
  }

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> with WidgetsBindingObserver {
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);
    languageService.addListener(_onLanguageChanged);
    // Reset to light mode first, then initialize from preferences
    _currentThemeMode = ThemeMode.light;
    print('✅ App starting with Light Mode');
    // Initialize theme from SharedPreferences
    themeService.initialize().then((_) {
      if (mounted) {
        setState(() {
          _currentThemeMode =
              themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
          print(
              '✅ Theme initialized: isDarkMode=${themeService.isDarkMode}, _currentThemeMode=$_currentThemeMode');
        });
      }
    });
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      print('🔄 _onThemeChanged() called');
      print('   isDarkMode=${themeService.isDarkMode}');
      print('   OLD _currentThemeMode=$_currentThemeMode');
      setState(() {
        _currentThemeMode =
            themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
        print('   NEW _currentThemeMode=$_currentThemeMode');
      });
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      print(
          '🔄 _onLanguageChanged() called: currentLanguage=${languageService.currentLanguage}');
      setState(() {
        // Erzwinge einen Rebuild wenn die Sprache wechselt
      });
    }
  }

  void _setThemeMode(ThemeMode mode) {
    if (!mounted) return;
    setState(() {
      _currentThemeMode = mode;
      print('   Set _currentThemeMode=$mode inside setState()');
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = const FlutterSecureStorageAdapter();
    // For demo purpose only: write a fake token so the production-style revocation
    // implementation can read it from secure storage. DO NOT use real tokens here.
    storage.write(key: 'ABACUS_API_TOKEN', value: 'demo-token');
    final service = RevocationServiceImpl(
        baseUrl: 'https://api.example.com', secureStorage: storage);

    final mockDevices = [
      TrustedDevice(
          deviceUuid: 'uuid-1',
          deviceName: 'Mamas iPhone',
          status: DeviceStatus.active),
      TrustedDevice(
          deviceUuid: 'uuid-2',
          deviceName: 'Papas Pixel',
          status: DeviceStatus.active),
      TrustedDevice(
          deviceUuid: 'fail-uuid',
          deviceName: 'Test Fail Device',
          status: DeviceStatus.active),
      TrustedDevice(
          deviceUuid: 'uuid-removed',
          deviceName: 'Altes iPad',
          status: DeviceStatus.revoked,
          revokedAt: DateTime.now().subtract(const Duration(days: 3))),
    ];

    return MaterialApp(
      title: 'Parentpeak',
      theme: themeService.getLightTheme(),
      darkTheme: themeService.getDarkTheme(),
      themeMode: _currentThemeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: LanguageProviderWrapper(
        child: ParentpeakAppShell(
          devices: mockDevices,
          onRevoke: (uuid, name) async {
            try {
              return await service.revokeDevice(uuid, 'Demo Revoke');
            } catch (e) {
              return false;
            }
          },
        ),
      ),
    );
  }
}

class ParentpeakAppShell extends StatefulWidget {
  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  const ParentpeakAppShell(
      {super.key, required this.devices, required this.onRevoke});

  @override
  State<ParentpeakAppShell> createState() => _ParentpeakAppShellState();
}

class _ParentpeakAppShellState extends State<ParentpeakAppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      print(
          '🌍 Sprache geändert in ParentpeakAppShell - erzwinge Rebuild aller Screens');
      setState(() {
        // Erzwinge einen Rebuild aller Tabs
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tabs = <Widget>[
      LanguageAwareWidget(
        key: ValueKey('home-${languageService.currentLanguage}'),
        child: HomeScreen(devices: widget.devices, onRevoke: widget.onRevoke),
      ),
      LanguageAwareWidget(
          key: ValueKey('chat-${languageService.currentLanguage}'),
          child: const ChatScreen()),
      LanguageAwareWidget(
          key: ValueKey('family-${languageService.currentLanguage}'),
          child: FamilyProfileScreen()),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: theme.colorScheme.primaryContainer,
          labelTextStyle: MaterialStateProperty.all(
            theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          height: 76,
          backgroundColor: theme.colorScheme.surface,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.family_restroom_outlined),
              selectedIcon: Icon(Icons.family_restroom_rounded),
              label: 'Familie',
            ),
          ],
        ),
      ),
    );
  }
}

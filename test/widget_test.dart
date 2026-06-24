import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/auth/login_screen.dart';
import 'package:trusted_circle_demo/ui/auth/paywall_screen.dart';
import 'package:trusted_circle_demo/ui/create_event_screen.dart';
import 'package:trusted_circle_demo/ui/events_activities_screen.dart';
import 'package:trusted_circle_demo/ui/family_circle_screen.dart';
import 'package:trusted_circle_demo/ui/home_screen.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

class _LoginSuccessHarness extends StatefulWidget {
  const _LoginSuccessHarness();

  @override
  State<_LoginSuccessHarness> createState() => _LoginSuccessHarnessState();
}

class _LoginSuccessHarnessState extends State<_LoginSuccessHarness> {
  bool _loggedIn = false;

  @override
  Widget build(BuildContext context) {
    if (_loggedIn) {
      return const Scaffold(body: Center(child: Text('LOGIN_OK')));
    }

    return LoginScreen(
      onLoginSuccess: () {
        if (!mounted) return;
        setState(() => _loggedIn = true);
      },
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthService.disableFirebaseInitForTesting = true;
    await AuthService.instance.logout();
  });

  testWidgets('AuthGate shows login when no user session exists',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(
        AuthGate(
          devices: const [],
          onRevoke: (_, __) async => true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('ParentpeakAppShell switches between Home and Profil tabs',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting();

    final devices = [
      TrustedDevice(
        deviceUuid: 'device-1',
        deviceName: 'Testgeraet',
        status: DeviceStatus.active,
      ),
    ];

    await tester.pumpWidget(
      _buildTestApp(
        ParentpeakAppShell(
          devices: devices,
          onRevoke: (_, __) async => true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Impulse & Entwicklung'), findsOneWidget);
    expect(find.text('Profil & Schutz'), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Profil & Schutz'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Impulse & Entwicklung'), findsOneWidget);
  });

  testWidgets('AuthGate shows paywall when trial has expired',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting(
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
      isPremium: false,
      serverHasFullAccess: false,
      serverTrialDaysRemaining: 0,
    );

    await tester.pumpWidget(
      _buildTestApp(
        AuthGate(
          devices: const [],
          onRevoke: (_, __) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.text('Parentpeak Premium'), findsOneWidget);
  });

  testWidgets('Home feature tile opens Familienkreis screen',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting();

    await tester.pumpWidget(
      _buildTestApp(
        const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Familienkreis'));
    await tester.pumpAndSettle();

    expect(find.byType(FamilyCircleScreen), findsOneWidget);
    expect(find.text('Familienkreis'), findsWidgets);
  });

  testWidgets('Home feature tile opens Events & Aktivitäten screen',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting();

    await tester.pumpWidget(
      _buildTestApp(
        const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events & Aktivitäten'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(EventsActivitiesScreen), findsOneWidget);
    expect(find.text('Events & Aktivitäten'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('LoginScreen logs in with valid local credentials',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final result = await AuthService.instance.register(
      email: 'release-test@parentpeak.app',
      password: 'StrongPass1',
      displayName: 'Release Test',
    );
    expect(result.success, isTrue);
    await AuthService.instance.logout();

    await tester.pumpWidget(
      _buildTestApp(
        const _LoginSuccessHarness(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'release-test@parentpeak.app',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      'StrongPass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_OK'), findsOneWidget);
  });

  testWidgets('Event creation screen opens from Events & Aktivitäten',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting();

    await tester.pumpWidget(
      _buildTestApp(
        const EventsActivitiesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event planen'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventScreen), findsOneWidget);
  });

  testWidgets('Event creation form loads without errors',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting();

    await tester.pumpWidget(
      _buildTestApp(
        const CreateEventScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsWidgets);
    expect(find.byType(FilterChip), findsWidgets);
    expect(find.text('Treffpunkt'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Family Circle shows incoming connection request',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting();

    await tester.pumpWidget(
      _buildTestApp(
        const FamilyCircleScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noah Weber'), findsOneWidget);
    expect(find.text('Ablehnen'), findsOneWidget);
    expect(find.text('Annehmen'), findsOneWidget);
  });

  testWidgets('PaywallScreen displays premium options',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting(
      isPremium: false,
      serverTrialDaysRemaining: 0,
    );

    await tester.pumpWidget(
      _buildTestApp(
        const PaywallScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('29,99 €'), findsOneWidget);
    expect(find.text('3,99 €'), findsOneWidget);
    expect(find.text('Jährlich'), findsOneWidget);
    expect(find.text('Monatlich'), findsOneWidget);
  });

  testWidgets('Home screen renders after login',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await AuthService.instance.debugSeedSessionForTesting();

    await tester.pumpWidget(
      _buildTestApp(
        const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
      'App flow covers start, login, home, profile tab, paywall and create event',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const email = 'flow-test@parentpeak.app';
    const password = 'StrongPass1';

    final registerResult = await AuthService.instance.register(
      email: email,
      password: password,
      displayName: 'Flow Test',
    );
    expect(registerResult.success, isTrue);
    await AuthService.instance.logout();

    await tester.pumpWidget(
      _buildTestApp(
        AuthGate(
          devices: const [],
          onRevoke: (_, __) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      password,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pumpAndSettle();

    expect(find.text('Impulse & Entwicklung'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil & Schutz'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events & Aktivitäten'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EventsActivitiesScreen), findsOneWidget);

    await tester.tap(find.text('Event planen'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateEventScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));

    await AuthService.instance.debugSeedSessionForTesting(
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
      isPremium: false,
      serverHasFullAccess: false,
      serverTrialDaysRemaining: 0,
    );

    await tester.pumpWidget(
      _buildTestApp(
        AuthGate(
          devices: const [],
          onRevoke: (_, __) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.text('Parentpeak Premium'), findsOneWidget);
  });
}
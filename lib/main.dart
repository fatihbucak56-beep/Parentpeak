import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trusted_circle_demo/logic/revocation_service_impl.dart';
import 'package:trusted_circle_demo/logic/secure_storage.dart';
import 'package:trusted_circle_demo/logic/background_sync_manager.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/device_management_screen.dart';
import 'package:trusted_circle_demo/ui/home_screen.dart';
import 'package:trusted_circle_demo/ui/chat_screen.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/location_screen.dart';
import 'package:trusted_circle_demo/ui/todo_screen.dart';
import 'package:trusted_circle_demo/ui/shopping_screen.dart';
import 'package:trusted_circle_demo/ui/photos_screen.dart';
import 'package:trusted_circle_demo/ui/contacts_screen.dart';
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
      title: 'Parentpeak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFE91E63),
          tertiary: const Color(0xFFFFC107),
          surface: const Color(0xFFF5EFE7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5EFE7),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2D3748),
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
            letterSpacing: -0.5,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF4A5568)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ParentpeakAppShell(
        devices: mockDevices,
        onRevoke: (uuid, name) async {
          try {
            return await service.revokeDevice(uuid, 'Demo Revoke');
          } catch (e) {
            return false;
          }
        },
      ),
    );
  }
}

class ParentpeakAppShell extends StatefulWidget {
  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  const ParentpeakAppShell({super.key, required this.devices, required this.onRevoke});

  @override
  State<ParentpeakAppShell> createState() => _ParentpeakAppShellState();
}

class _ParentpeakAppShellState extends State<ParentpeakAppShell> {
  int _index = 0;

  Widget _buildNavItem(int index, IconData icon, String label, ThemeData theme) {
    final isSelected = _index == index;
    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? theme.colorScheme.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    final tabs = <Widget>[
      const HomeScreen(),
      const ChatScreen(),
      const CalendarScreen(),
      const LocationScreen(),
      _DashboardScreen(devices: widget.devices, onRevoke: widget.onRevoke),
    ];

    final titles = <String>[
      'Home',
      loc.chatTitle,
      loc.calendarTitle,
      loc.locationTitle,
      'Profil',
    ];

    return Scaffold(
      body: tabs[_index],
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _index = 1),
        backgroundColor: theme.colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home', theme),
              _buildNavItem(2, Icons.event_rounded, 'Kalender', theme),
              const SizedBox(width: 64), // Space for FAB
              _buildNavItem(3, Icons.location_on_rounded, 'Standort', theme),
              _buildNavItem(4, Icons.person_rounded, 'Profil', theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardScreen extends StatelessWidget {
  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  const _DashboardScreen({required this.devices, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    
    return Container(
      color: const Color(0xFFF5F7FA),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section Header
          Text(
            'Deine Bereiche',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 8),
          Text(
            'Alle Funktionen auf einen Blick',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Feature Cards
          _buildFeatureCard(
            context,
            icon: Icons.check_box_rounded,
            title: loc.todoLabel,
            subtitle: 'Aufgaben verwalten',
            color: const Color(0xFF00BFA5),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoScreen())),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            icon: Icons.shopping_cart_rounded,
            title: loc.shoppingLabel,
            subtitle: 'Einkaufsliste erstellen',
            color: const Color(0xFFFF6B9D),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingScreen())),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            icon: Icons.photo_library_rounded,
            title: loc.photosLabel,
            subtitle: 'Familienmomente teilen',
            color: const Color(0xFFFFC107),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotosScreen())),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            icon: Icons.contact_phone_rounded,
            title: loc.contactsLabel,
            subtitle: 'Notfallkontakte',
            color: const Color(0xFFE91E63),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

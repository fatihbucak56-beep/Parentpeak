import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';
import 'package:trusted_circle_demo/ui/contacts_screen.dart';
import 'package:trusted_circle_demo/ui/device_management_screen.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/location_screen.dart';
import 'package:trusted_circle_demo/ui/photos_screen.dart';
import 'package:trusted_circle_demo/ui/safety_guide_screen.dart';
import 'package:trusted_circle_demo/ui/shopping_screen.dart';
import 'package:trusted_circle_demo/ui/todo_screen.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/backend_status_screen.dart';

class _FeatureAction {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _FeatureAction({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

class HomeScreen extends StatefulWidget {
  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  const HomeScreen({super.key, required this.devices, required this.onRevoke});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      setState(() {
        // Erzwinge Rebuild wenn Sprache wechselt
      });
    }
  }

  String _t(String key) {
    return AppStringsManager.getString(languageService.currentLanguage, key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final hour = now.hour;
    final featureActions = <_FeatureAction>[
      _FeatureAction(
        label: 'Kalender',
        description: 'Termine und Familienplan',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF2563EB),
        builder: (_) => const CalendarScreen(),
      ),
      _FeatureAction(
        label: 'To-do',
        description: 'Aufgaben und Erledigungen',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF059669),
        builder: (_) => const TodoScreen(),
      ),
      _FeatureAction(
        label: 'Einkauf',
        description: 'Einkaufsliste gemeinsam pflegen',
        icon: Icons.shopping_cart_rounded,
        color: const Color(0xFFEC4899),
        builder: (_) => const ShoppingScreen(),
      ),
      _FeatureAction(
        label: 'Fotos',
        description: 'Bilder und Erinnerungen',
        icon: Icons.photo_library_rounded,
        color: const Color(0xFFF59E0B),
        builder: (_) => const PhotosScreen(),
      ),
      _FeatureAction(
        label: 'Kontakte',
        description: 'Wichtige Kontakte schnell öffnen',
        icon: Icons.contact_phone_rounded,
        color: const Color(0xFFE11D48),
        builder: (_) => const ContactsScreen(),
      ),
      _FeatureAction(
        label: 'Standort',
        description: 'Orte und Treffpunkte finden',
        icon: Icons.location_on_rounded,
        color: const Color(0xFFF97316),
        builder: (_) => const LocationScreen(),
      ),
      _FeatureAction(
        label: 'Geräte',
        description: 'Vertrauensgeräte verwalten',
        icon: Icons.phonelink_setup_rounded,
        color: const Color(0xFF0891B2),
        builder: (_) => DeviceManagementScreen(
          devices: widget.devices,
          onRevoke: widget.onRevoke,
        ),
      ),
      _FeatureAction(
        label: 'Sicherheit',
        description: 'Richtlinien und Schutz auf einen Blick',
        icon: Icons.shield_rounded,
        color: const Color(0xFF6366F1),
        builder: (_) => const SafetyGuideScreen(),
      ),
      _FeatureAction(
        label: 'Systemstatus',
        description: 'API-Verbindung und Endpunkte prüfen',
        icon: Icons.cloud_sync_rounded,
        color: const Color(0xFF0F766E),
        builder: (_) => const BackendStatusScreen(),
      ),
    ];

    String greeting = _t('greeting_morning');
    if (hour >= 12 && hour < 18) {
      greeting = _t('greeting_afternoon');
    } else if (hour >= 18) {
      greeting = _t('greeting_evening');
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildHeroCard(theme, greeting),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: _buildSectionHeader(
                  title: 'Schnellzugriff',
                  subtitle: 'Die wichtigsten Funktionen auf einen Blick',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final action = featureActions[index];
                    return _buildFeatureTile(
                      context,
                      title: action.label,
                      subtitle: action.description,
                      icon: action.icon,
                      color: action.color,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: action.builder),
                      ),
                    );
                  },
                  childCount: featureActions.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, String greeting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.family_restroom_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alles für eure Familie an einem Ort',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Termine, Chat und Familie schneller erreichen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String title, required String subtitle}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.16), color.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

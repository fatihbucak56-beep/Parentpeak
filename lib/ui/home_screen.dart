import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';
import 'package:trusted_circle_demo/ui/photos_screen.dart';
import 'package:trusted_circle_demo/ui/safety_guide_screen.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/backend_status_screen.dart';
import 'package:trusted_circle_demo/ui/events_activities_screen.dart';
import 'package:trusted_circle_demo/ui/event_invitations_screen.dart';
import 'package:trusted_circle_demo/ui/family_circle_screen.dart';
import 'package:trusted_circle_demo/ui/organization_screen.dart';
import 'package:trusted_circle_demo/ui/entwicklung_impulse_screen.dart';
import 'package:trusted_circle_demo/ui/parent_matching_screen.dart';
import 'package:trusted_circle_demo/ui/chat_screen.dart';
import 'package:trusted_circle_demo/models_and_widgets/weekly_impulse_feature.dart';
import 'package:trusted_circle_demo/models_and_widgets/development_schema_feature.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';

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
  final String? initialInviteInput;

  const HomeScreen({super.key, this.initialInviteInput});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  WeeklyImpulse? _weeklyImpulse;
  bool _isLoadingWeeklyImpulse = true;
  bool _initialInviteHandled = false;

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _loadWeeklyImpulse();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialInviteIfNeeded();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadWeeklyImpulse() async {
    try {
      final service = BackendServiceFactory.createWeeklyImpulseService();
      final impulse = await service.fetchWeeklyImpulse();
      if (!mounted) return;
      setState(() {
        _weeklyImpulse = impulse;
        _isLoadingWeeklyImpulse = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeeklyImpulse = false;
      });
    }
  }

  void _openInitialInviteIfNeeded() {
    if (_initialInviteHandled) return;
    final input = widget.initialInviteInput?.trim();
    if (input == null || input.isEmpty || !mounted) return;

    _initialInviteHandled = true;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventInvitationsScreen(initialInviteInput: input),
      ),
    );
  }

  Future<void> _playWeeklyImpulseAudio() async {
    final text = _weeklyImpulse?.audioScript;
    if (text == null || text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Audio-Skript verfuegbar.')),
      );
      return;
    }

    await _tts.stop();
    try {
      await _tts.setLanguage(_resolveTtsLocale(languageService.currentLanguage));
    } catch (_) {
      await _tts.setLanguage('de-DE');
    }
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.47);
    await _tts.speak(text);
  }

  String _resolveTtsLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-PT';
      case 'nl':
        return 'nl-NL';
      case 'ar':
        return 'ar-SA';
      case 'fa':
        return 'fa-IR';
      case 'ku':
        return 'ku';
      case 'ckb':
        return 'ckb';
      case 'zh':
        return 'zh-CN';
      case 'ja':
        return 'ja-JP';
      case 'hi':
        return 'hi-IN';
      case 'tr':
        return 'tr-TR';
      case 'ru':
        return 'ru-RU';
      case 'de':
      default:
        return 'de-DE';
    }
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
        label: 'Impulse & Entwicklung',
        description: 'Wochenimpuls und Entwicklung in einem Bereich',
        icon: Icons.auto_awesome_mosaic_rounded,
        color: const Color(0xFF0EA5A4),
        builder: (_) => const EntwicklungImpulseScreen(),
      ),
      _FeatureAction(
        label: 'Kalender',
        description: 'Termine und Familienplan',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF2563EB),
        builder: (_) => const CalendarScreen(),
      ),
      _FeatureAction(
        label: 'Events & Aktivitäten',
        description: 'Aktivitäten entdecken, erstellen und Einladungen steuern',
        icon: Icons.celebration_rounded,
        color: const Color(0xFF8B5CF6),
        builder: (_) => const EventsActivitiesScreen(),
      ),
      _FeatureAction(
        label: 'Familienkreis',
        description: 'Vertrauenskontakte verwalten und Einladungen steuern',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF4F46E5),
        builder: (_) => const FamilyCircleScreen(),
      ),
      _FeatureAction(
        label: 'Eltern Match',
        description: 'Eltern finden fuer Playdates und Austausch',
        icon: Icons.diversity_3_rounded,
        color: const Color(0xFF0EA5A4),
        builder: (_) => const ParentMatchingScreen(),
      ),
      _FeatureAction(
        label: 'KI Elternberatung',
        description: 'Schnelle Hilfe und Tipps rund um Erziehung',
        icon: Icons.tips_and_updates_rounded,
        color: const Color(0xFF0284C7),
        builder: (_) => const ChatScreen(),
      ),
      _FeatureAction(
        label: 'Organisation',
        description: 'To-do und Einkauf in einem Bereich',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF16A34A),
        builder: (_) => const OrganizationScreen(),
      ),
      _FeatureAction(
        label: 'Fotos',
        description: 'Bilder und Erinnerungen',
        icon: Icons.photo_library_rounded,
        color: const Color(0xFFF59E0B),
        builder: (_) => const PhotosScreen(),
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
                  childAspectRatio: 0.85,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTabs(ThemeData theme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Entwicklung und Impulse',
            subtitle: 'Zwei kompakte Tabs statt langer Karten im Home',
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: theme.colorScheme.onPrimaryContainer,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(icon: Icon(Icons.wb_sunny_rounded), text: 'Wochenimpuls'),
                Tab(icon: Icon(Icons.checklist_rtl_rounded), text: 'Entwicklung'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _buildWeeklyImpulsePreview(theme),
                _buildDevelopmentPreview(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyImpulsePreview(ThemeData theme) {
    if (_isLoadingWeeklyImpulse) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Wochenimpuls wird geladen...')),
            ],
          ),
        ),
      );
    }

    if (_weeklyImpulse == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wochenimpuls aktuell nicht verfuegbar',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Bitte pruefe die Backend-Verbindung und versuche es erneut.',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isLoadingWeeklyImpulse = true);
                  _loadWeeklyImpulse();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut laden'),
              ),
            ],
          ),
        ),
      );
    }

    final impulse = _weeklyImpulse!;
    final shortBody = impulse.contentBody.length > 160
        ? '${impulse.contentBody.substring(0, 160)}...'
        : impulse.contentBody;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    impulse.category == PedagogicalCategory.gfk
                        ? 'Gewaltfreie Kommunikation'
                        : 'Paedagogischer Impuls',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (impulse.audioScript != null)
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: _playWeeklyImpulseAudio,
                    tooltip: 'Audio-Impuls anhoeren',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              impulse.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                shortBody,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: _openWeeklyImpulseDetails,
                child: const Text('Vollansicht'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevelopmentPreview(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entwicklungsschema fuer Eltern',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Kinder 1 bis 3, Altersphasen von 0 bis 18 Jahren und Status pro Meilenstein.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('0-12 Monate')),
                Chip(label: Text('1-3 Jahre')),
                Chip(label: Text('3-6 Jahre')),
              ],
            ),
            const Spacer(),
            Text(
              'Die Detailansicht ist nur einen Tipp entfernt.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: _openDevelopmentDetails,
                child: const Text('Vollansicht'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWeeklyImpulseDetails() {
    if (_weeklyImpulse == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: WeeklyImpulseCard(
              impulse: _weeklyImpulse!,
              onAudioPressed: _playWeeklyImpulseAudio,
            ),
          ),
        );
      },
    );
  }

  void _openDevelopmentDetails() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: const DevelopmentSchemaCard(),
          ),
        );
      },
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactTile =
                constraints.maxWidth < 150 || constraints.maxHeight < 210;

            return Container(
              padding: EdgeInsets.all(compactTile ? 14 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.16), color.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: (compactTile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: compactTile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

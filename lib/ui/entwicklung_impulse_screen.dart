import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/models_and_widgets/weekly_impulse_feature.dart';
import 'package:trusted_circle_demo/models_and_widgets/development_schema_feature.dart';

class EntwicklungImpulseScreen extends StatefulWidget {
  const EntwicklungImpulseScreen({super.key});

  @override
  State<EntwicklungImpulseScreen> createState() =>
      _EntwicklungImpulseScreenState();
}

class _EntwicklungImpulseScreenState extends State<EntwicklungImpulseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FlutterTts _tts = FlutterTts();

  WeeklyImpulse? _weeklyImpulse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadImpulse();
  }

  @override
  void dispose() {
    _tts.stop();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImpulse() async {
    try {
      final service = BackendServiceFactory.createWeeklyImpulseService();
      final impulse = await service.fetchWeeklyImpulse();
      if (!mounted) return;
      setState(() {
        _weeklyImpulse = impulse;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playAudio() async {
    final text = _weeklyImpulse?.audioScript;
    if (text == null || text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Audio-Skript verfuegbar.')),
      );
      return;
    }
    await _tts.stop();
    if (!mounted) return;
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      await _tts.setLanguage(_resolveTtsLocale(languageCode));
    } catch (_) {
      await _tts.setLanguage('de-DE');
    }
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.47);
    await _tts.speak(text);
  }

  String _resolveTtsLocale(String code) {
    switch (code) {
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'tr':
        return 'tr-TR';
      case 'ar':
        return 'ar-SA';
      case 'fa':
        return 'fa-IR';
      default:
        return 'de-DE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impulse & Entwicklung'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _buildTopHeader(theme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: theme.colorScheme.onPrimaryContainer,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.wb_sunny_rounded),
                    text: 'Wochenimpuls',
                  ),
                  Tab(
                    icon: Icon(Icons.checklist_rtl_rounded),
                    text: 'Entwicklung',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWochenimpulsTab(theme),
                const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: DevelopmentSchemaCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                Positioned(
                  right: 8,
                  bottom: 7,
                  child: Icon(Icons.trending_up_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impulse & Entwicklung',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ein eigener Bereich wie Kalender und Organisation.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWochenimpulsTab(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weeklyImpulse == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Wochenimpuls nicht verfuegbar',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bitte Backend-Verbindung pruefen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadImpulse();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut laden'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: WeeklyImpulseCard(
        impulse: _weeklyImpulse!,
        onAudioPressed: _playAudio,
      ),
    );
  }
}

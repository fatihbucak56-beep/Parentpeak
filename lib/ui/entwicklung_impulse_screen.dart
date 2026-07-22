import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/backend_service_factory.dart';
import 'package:parentpeak/logic/weekly_impulse_service.dart';
import 'package:parentpeak/models_and_widgets/weekly_impulse_feature.dart';
import 'package:parentpeak/ui/chat_screen.dart';

/// Impulse & Entwicklung — vereinfacht, elternfreundlich, modern.
///
/// Tab 1: Wochenimpuls mit 3 Mini-Formaten (Verstehen, Praxis, Reflexion)
/// Tab 2: Entwicklungs-Check-in (5 Bereiche, Radar-Chart, KI-Tipps)
class EntwicklungImpulseScreen extends StatefulWidget {
  final int initialTabIndex;

  const EntwicklungImpulseScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<EntwicklungImpulseScreen> createState() =>
      _EntwicklungImpulseScreenState();
}

class _EntwicklungImpulseScreenState extends State<EntwicklungImpulseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FlutterTts _tts = FlutterTts();
  final WeeklyImpulseService _impulseService =
      BackendServiceFactory.createWeeklyImpulseService();

  WeeklyImpulse? _impulse;
  bool _isLoading = true;
  String? _error;
  bool _isPlayingAudio = false;
  int _expandedFormat = -1; // welches Mini-Format aufgeklappt ist

  // Entwicklung Check-in State
  final Map<String, int> _checkInAnswers = {}; // domainId -> 0/1/2
  bool _checkInDone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadImpulse();
    _loadCheckIn();
  }

  @override
  void dispose() {
    _tts.stop();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImpulse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final impulse = await _impulseService.fetchWeeklyImpulse(
        viewerUserId: AuthService.instance.currentUser?.uid ?? 'guest',
      );
      if (mounted)
        setState(() {
          _impulse = impulse;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Impuls konnte nicht geladen werden.';
          _isLoading = false;
        });
    }
  }

  Future<void> _loadCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('dev_checkin.answers');
    if (saved != null && saved.isNotEmpty) {
      final parts = saved.split(',');
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          _checkInAnswers[kv[0]] = int.tryParse(kv[1]) ?? 0;
        }
      }
      if (mounted) setState(() => _checkInDone = _checkInAnswers.length >= 5);
    }
  }

  Future<void> _saveCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        _checkInAnswers.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString('dev_checkin.answers', encoded);
  }

  Future<void> _playAudio(String text) async {
    if (_isPlayingAudio) {
      await _tts.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }
    setState(() => _isPlayingAudio = true);
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impulse & Entwicklung'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: theme.colorScheme.onPrimaryContainer,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Wochenimpuls'),
                  Tab(text: 'Entwicklung'),
                ],
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildImpulseTab(theme),
                _buildDevelopmentTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: WOCHENIMPULS — 3 Mini-Formate
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildImpulseTab(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _impulse == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 14),
              Text(_error ?? 'Nicht verfügbar', textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: _loadImpulse,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut laden'),
              ),
            ],
          ),
        ),
      );
    }

    final impulse = _impulse!;
    final companions = impulse.companionImpulses;

    return RefreshIndicator(
      onRefresh: _loadImpulse,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thema der Woche
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('\u{1F4D6}', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Thema der Woche',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      // Audio Button
                      if (impulse.audioScript != null)
                        GestureDetector(
                          onTap: () => _playAudio(
                              impulse.audioScript ?? impulse.contentBody),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isPlayingAudio
                                  ? Icons.stop_rounded
                                  : Icons.headphones_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    impulse.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    impulse.heroDescription ??
                        impulse.contentBody.split('\n').first,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Schriftlicher Inhalt — aufklappbar
            _buildContentSection(theme, impulse),
            const SizedBox(height: 20),

            // 3 Mini-Formate
            _buildMiniFormat(
              theme,
              index: 0,
              emoji: '\u{26A1}',
              title: companions.isNotEmpty
                  ? companions[0].title
                  : 'Kurz verstanden',
              duration:
                  companions.isNotEmpty ? companions[0].durationLabel : '2 Min',
              content: companions.isNotEmpty
                  ? companions[0].summary
                  : impulse.contentBody.split('\n').first,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 10),
            _buildMiniFormat(
              theme,
              index: 1,
              emoji: '\u{1F3AF}',
              title: companions.length > 2
                  ? companions[2].title
                  : 'Praxis für heute',
              duration:
                  companions.length > 2 ? companions[2].durationLabel : '5 Min',
              content: impulse.practicalTip,
              color: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 10),
            _buildMiniFormat(
              theme,
              index: 2,
              emoji: '\u{1F31F}',
              title: companions.length > 3
                  ? companions[3].title
                  : 'Abend-Reflexion',
              duration:
                  companions.length > 3 ? companions[3].durationLabel : '2 Min',
              content: companions.length > 3
                  ? companions[3].summary
                  : 'Was hat heute gut funktioniert? Welchen Moment mit deinem Kind willst du festhalten?',
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 20),

            // KI-Vertiefung
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      initialMessage:
                          '___TIP_EXPAND___${impulse.title}: ${impulse.practicalTip}',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mehr erfahren',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Die KI erklärt dir das Thema persönlich',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFormat(
    ThemeData theme, {
    required int index,
    required String emoji,
    required String title,
    required String duration,
    required String content,
    required Color color,
  }) {
    final isExpanded = _expandedFormat == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _expandedFormat = isExpanded ? -1 : index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpanded
              ? color.withValues(alpha: 0.06)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? color.withValues(alpha: 0.2)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // Audio für diesen Abschnitt
              GestureDetector(
                onTap: () => _playAudio(content),
                child: Row(
                  children: [
                    Icon(
                      _isPlayingAudio
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPlayingAudio ? 'Stoppen' : 'Vorlesen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Schriftlicher Inhalt des Wochenimpulses ─────────────────────────────────

  bool _contentExpanded = false;

  Widget _buildContentSection(ThemeData theme, WeeklyImpulse impulse) {
    final content = impulse.contentBody;
    final lines =
        content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final preview = lines.take(3).join('\n');
    final hasMore = lines.length > 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\u{1F4DD}', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Zum Lesen',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (impulse.audioScript != null)
                GestureDetector(
                  onTap: () => _playAudio(impulse.audioScript ?? content),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlayingAudio
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPlayingAudio ? 'Stop' : 'Vorlesen',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _contentExpanded ? content : preview,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (hasMore) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _contentExpanded = !_contentExpanded),
              child: Row(
                children: [
                  Text(
                    _contentExpanded ? 'Weniger zeigen' : 'Weiterlesen',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _contentExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: ENTWICKLUNGS-CHECK-IN — 15 Fragen + Bericht + PDF
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<_DevDomain> _domains = [
    _DevDomain(
        id: 'motorik',
        title: 'Bewegung & Motorik',
        emoji: '\u{1F3C3}',
        color: Color(0xFF0EA5E9),
        tipWhenLow: 'Wie foerdere ich die Motorik meines Kindes spielerisch?',
        questions: [
          'Bewegt sich dein Kind sicher (laufen, klettern, balancieren)?',
          'Probiert dein Kind neue Bewegungen mutig aus?',
          'Gelingen feinmotorische Aufgaben (malen, schneiden, greifen)?'
        ]),
    _DevDomain(
        id: 'sprache',
        title: 'Sprache & Ausdruck',
        emoji: '\u{1F4AC}',
        color: Color(0xFF16A34A),
        tipWhenLow:
            'Wie kann ich die Sprache meines Kindes im Alltag foerdern?',
        questions: [
          'Kann dein Kind Beduerfnisse klar ausdruecken?',
          'Versteht dein Kind alltaegliche Anweisungen gut?',
          'Erzaehlt dein Kind von Erlebnissen in eigenen Worten?'
        ]),
    _DevDomain(
        id: 'denken',
        title: 'Denken & Neugier',
        emoji: '\u{1F4A1}',
        color: Color(0xFFF59E0B),
        tipWhenLow:
            'Wie foerdere ich die Neugier und das Denken meines Kindes?',
        questions: [
          'Stellt dein Kind Fragen und will Dinge verstehen?',
          'Bleibt dein Kind bei interessanten Aufgaben dran?',
          'Probiert dein Kind verschiedene Loesungswege aus?'
        ]),
    _DevDomain(
        id: 'sozial',
        title: 'Gefuehle & Soziales',
        emoji: '\u{1F49C}',
        color: Color(0xFFEC4899),
        tipWhenLow:
            'Wie unterstuetze ich die emotionale Entwicklung meines Kindes?',
        questions: [
          'Kann dein Kind Gefuehle benennen oder zeigen?',
          'Findet dein Kind nach Frust wieder zur Ruhe?',
          'Sucht dein Kind Kontakt zu anderen Kindern?'
        ]),
    _DevDomain(
        id: 'selbst',
        title: 'Selbststaendigkeit',
        emoji: '\u{1F31F}',
        color: Color(0xFF8B5CF6),
        tipWhenLow:
            'Wie foerdere ich die Selbststaendigkeit meines Kindes altersgerecht?',
        questions: [
          'Uebernimmt dein Kind kleine Alltagsaufgaben?',
          'Versucht dein Kind Probleme erst selbst zu loesen?',
          'Kann dein Kind einfache Ablaeufe alleine umsetzen?'
        ]),
  ];

  Widget _buildDevelopmentTab(ThemeData theme) {
    final totalQ = _domains.fold(0, (int s, d) => s + d.questions.length);
    final answered = _checkInAnswers.length;
    final allDone = answered >= totalQ;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Entwicklungs-Check-in',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
            '15 kurze Fragen zu 5 Bereichen. Kein Test — ein liebevoller Blick auf dein Kind.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: totalQ > 0 ? answered / totalQ : 0,
                      minHeight: 5,
                      backgroundColor: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary)))),
          const SizedBox(width: 10),
          Text('$answered/$totalQ',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary)),
        ]),
        const SizedBox(height: 20),
        ..._domains.map((d) => _buildDomainSection(theme, d)),
        if (allDone) ...[
          const SizedBox(height: 24),
          _buildRadarChart(theme),
          const SizedBox(height: 16),
          _buildReport(theme),
          const SizedBox(height: 16),
          _buildDownloadButton(theme),
          const SizedBox(height: 16),
          _buildFocusTip(theme),
          const SizedBox(height: 20),
          Center(
              child: TextButton.icon(
                  onPressed: _resetCheckIn,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Nochmal machen')))
        ],
      ]),
    );
  }

  Widget _buildDomainSection(ThemeData theme, _DevDomain domain) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: domain.color.withValues(alpha: 0.12))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(domain.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(domain.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800))
              ]),
              const SizedBox(height: 14),
              ...domain.questions.asMap().entries.map((e) {
                final key = '${domain.id}_${e.key}';
                return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(height: 1.3)),
                          const SizedBox(height: 8),
                          Row(children: [
                            _buildChip(
                                theme, key, 2, 'Ja', const Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            _buildChip(theme, key, 1, 'Manchmal',
                                const Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            _buildChip(theme, key, 0, 'Noch nicht',
                                const Color(0xFFEF4444))
                          ]),
                        ]));
              }),
            ])));
  }

  Widget _buildChip(
      ThemeData theme, String key, int val, String label, Color color) {
    final sel = _checkInAnswers[key] == val;
    return Expanded(
        child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _checkInAnswers[key] = val;
                _checkInDone = _checkInAnswers.length >= 15;
              });
              _saveCheckIn();
            },
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                    color: sel
                        ? color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? color : theme.colorScheme.outlineVariant,
                        width: sel ? 2 : 1)),
                child: Center(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? color
                                : theme.colorScheme.onSurfaceVariant))))));
  }

  Widget _buildReport(ThemeData theme) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('\u{1F4CB}', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Entwicklungsbericht',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800))
          ]),
          const SizedBox(height: 14),
          ..._domains.map((d) {
            final scores = d.questions
                .asMap()
                .entries
                .map((e) => _checkInAnswers['${d.id}_${e.key}'] ?? 0)
                .toList();
            final avg = scores.fold(0, (int a, b) => a + b) / scores.length;
            final level = avg >= 1.7
                ? 'Stark'
                : avg >= 0.8
                    ? 'In Entwicklung'
                    : 'Foerderbedarf';
            final lc = avg >= 1.7
                ? const Color(0xFF16A34A)
                : avg >= 0.8
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444);
            return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(d.title,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600))),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: lc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(level,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: lc)))
                ]));
          }),
          const SizedBox(height: 12),
          Text(_reportText(),
              style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.5, color: theme.colorScheme.onSurfaceVariant)),
        ]));
  }

  String _reportText() {
    final strong = <String>[];
    final dev = <String>[];
    final need = <String>[];
    for (final d in _domains) {
      final scores = d.questions
          .asMap()
          .entries
          .map((e) => _checkInAnswers['${d.id}_${e.key}'] ?? 0)
          .toList();
      final avg = scores.fold(0, (int a, b) => a + b) / scores.length;
      if (avg >= 1.7)
        strong.add(d.title);
      else if (avg >= 0.8)
        dev.add(d.title);
      else
        need.add(d.title);
    }
    final p = <String>[];
    if (strong.isNotEmpty)
      p.add(
          'Stark: ${strong.join(", ")}. Hier zeigt euer Kind sichere Kompetenz.');
    if (dev.isNotEmpty)
      p.add(
          'In Entwicklung: ${dev.join(", ")}. Mit eurer Begleitung waechst das gut.');
    if (need.isNotEmpty)
      p.add(
          'Foerderbedarf: ${need.join(", ")}. Kleine spielerische Impulse koennen viel bewirken.');
    return p.isEmpty ? '' : p.join('\n\n');
  }

  Widget _buildDownloadButton(ThemeData theme) {
    return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
            onPressed: _downloadReport,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Bericht als PDF speichern'),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)))));
  }

  Future<void> _downloadReport() async {
    HapticFeedback.mediumImpact();
    final date = DateTime.now();
    final dateStr = '${date.day}.${date.month}.${date.year}';
    final doc = pw.Document();
    doc.addPage(pw.Page(
        build: (ctx) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ParentPeak Entwicklungsbericht',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Erstellt am $dateStr',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 20),
                  ..._domains.map((d) {
                    final scores = d.questions
                        .asMap()
                        .entries
                        .map((e) => _checkInAnswers['${d.id}_${e.key}'] ?? 0)
                        .toList();
                    final avg =
                        scores.fold(0, (int a, b) => a + b) / scores.length;
                    final level = avg >= 1.7
                        ? 'Stark'
                        : avg >= 0.8
                            ? 'In Entwicklung'
                            : 'Foerderbedarf';
                    return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${d.title}: $level',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          ...d.questions.asMap().entries.map((e) {
                            final a = _checkInAnswers['${d.id}_${e.key}'] ?? 0;
                            return pw.Text(
                                '  ${e.value} - ${a == 2 ? "Ja" : a == 1 ? "Manchmal" : "Noch nicht"}',
                                style: const pw.TextStyle(fontSize: 11));
                          }),
                          pw.SizedBox(height: 10)
                        ]);
                  }),
                  pw.SizedBox(height: 16),
                  pw.Text('Zusammenfassung:',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(_reportText(),
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      'Hinweis: Dieser Bericht ist eine Orientierung, keine professionelle Diagnostik.',
                      style: const pw.TextStyle(fontSize: 9)),
                ])));
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  Widget _buildRadarChart(ThemeData theme) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
        child: Column(children: [
          Text('Euer Ueberblick',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                  painter: _SimpleRadarPainter(
                      values: _domains.map((d) {
                        final s = d.questions
                            .asMap()
                            .entries
                            .map(
                                (e) => _checkInAnswers['${d.id}_${e.key}'] ?? 0)
                            .toList();
                        return s.fold(0, (int a, b) => a + b) / (s.length * 2);
                      }).toList(),
                      colors: _domains.map((d) => d.color).toList()))),
          const SizedBox(height: 16),
          Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _domains
                  .map((d) => Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: d.color,
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 4),
                        Text(d.title.split(' ').first,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10))
                      ]))
                  .toList()),
        ]));
  }

  Widget _buildFocusTip(ThemeData theme) {
    _DevDomain? w;
    double low = 3;
    for (final d in _domains) {
      final s = d.questions
          .asMap()
          .entries
          .map((e) => _checkInAnswers['${d.id}_${e.key}'] ?? 0)
          .toList();
      final a = s.fold(0, (int x, y) => x + y) / s.length;
      if (a < low) {
        low = a;
        w = d;
      }
    }
    if (w == null || low >= 1.7)
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Text('\u{2728}', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Super! Euer Kind entwickelt sich toll.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A))))
          ]));
    return GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChatScreen(
                    initialMessage: '___TIP_EXPAND___${w!.tipWhenLow}'))),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: w.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: w.color.withValues(alpha: 0.15))),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: w.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      Icon(Icons.lightbulb_rounded, color: w.color, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${w.title} foerdern',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('KI-Tipps holen',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant))
                  ])),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: w.color)
            ])));
  }

  void _resetCheckIn() {
    HapticFeedback.mediumImpact();
    setState(() {
      _checkInAnswers.clear();
      _checkInDone = false;
    });
    _saveCheckIn();
  }
}

class _SimpleRadarPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  const _SimpleRadarPainter({required this.values, required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide / 2) - 12;
    final n = values.length;
    final gp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE2E8F0);
    for (int ring = 1; ring <= 3; ring++) {
      final rr = r * ring / 3;
      final p = Path();
      for (int i = 0; i < n; i++) {
        final a = (-90 + 360 / n * i) * math.pi / 180;
        final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      p.close();
      canvas.drawPath(p, gp);
    }
    final vp = Path();
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final a = (-90 + 360 / n * i) * math.pi / 180;
      final pt = Offset(c.dx + r * v * math.cos(a), c.dy + r * v * math.sin(a));
      i == 0 ? vp.moveTo(pt.dx, pt.dy) : vp.lineTo(pt.dx, pt.dy);
    }
    vp.close();
    canvas.drawPath(
        vp,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.2));
    canvas.drawPath(
        vp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFF0EA5E9));
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final a = (-90 + 360 / n * i) * math.pi / 180;
      canvas.drawCircle(
          Offset(c.dx + r * v * math.cos(a), c.dy + r * v * math.sin(a)),
          4,
          Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleRadarPainter old) => old.values != values;
}

class _DevDomain {
  final String id;
  final String title;
  final String emoji;
  final Color color;
  final String tipWhenLow;
  final List<String> questions;
  const _DevDomain(
      {required this.id,
      required this.title,
      required this.emoji,
      required this.color,
      required this.tipWhenLow,
      required this.questions});
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                ],
              ),
            ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: ENTWICKLUNGS-CHECK-IN — Simple 5-Domain Fragen
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<_DevDomain> _domains = [
    _DevDomain(
      id: 'motorik',
      title: 'Bewegung & Motorik',
      emoji: '\u{1F3C3}',
      question: 'Bewegt sich dein Kind sicher und probiert Neues aus?',
      tipWhenLow: 'Wie fördere ich die Motorik meines Kindes spielerisch?',
      color: Color(0xFF0EA5E9),
    ),
    _DevDomain(
      id: 'sprache',
      title: 'Sprache & Ausdruck',
      emoji: '\u{1F4AC}',
      question: 'Kann dein Kind sich gut ausdrücken und versteht dich?',
      tipWhenLow: 'Wie kann ich die Sprache meines Kindes im Alltag fördern?',
      color: Color(0xFF16A34A),
    ),
    _DevDomain(
      id: 'denken',
      title: 'Denken & Neugier',
      emoji: '\u{1F4A1}',
      question: 'Stellt dein Kind Fragen und bleibt bei Aufgaben dran?',
      tipWhenLow: 'Wie fördere ich die Neugier und das Denken meines Kindes?',
      color: Color(0xFFF59E0B),
    ),
    _DevDomain(
      id: 'sozial',
      title: 'Gefühle & Soziales',
      emoji: '\u{1F49C}',
      question: 'Kann dein Kind Gefühle zeigen und mit anderen umgehen?',
      tipWhenLow:
          'Wie unterstütze ich die emotionale Entwicklung meines Kindes?',
      color: Color(0xFFEC4899),
    ),
    _DevDomain(
      id: 'selbst',
      title: 'Selbstständigkeit',
      emoji: '\u{1F31F}',
      question: 'Macht dein Kind Dinge zunehmend alleine?',
      tipWhenLow:
          'Wie fördere ich die Selbstständigkeit meines Kindes altersgerecht?',
      color: Color(0xFF8B5CF6),
    ),
  ];

  Widget _buildDevelopmentTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Wie geht\u{0027}s deinem Kind?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ein kurzer Check-in — kein Test, kein Urteil. Nur ein Blick auf 5 Bereiche.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // 5 Domain-Fragen
          ..._domains.map((domain) => _buildDomainQuestion(theme, domain)),

          // Radar Chart (wenn Check-in fertig)
          if (_checkInDone) ...[
            const SizedBox(height: 24),
            _buildRadarChart(theme),
            const SizedBox(height: 16),
            _buildFocusTip(theme),
          ],

          // Reset Button
          if (_checkInDone) ...[
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: _resetCheckIn,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Nochmal machen'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDomainQuestion(ThemeData theme, _DevDomain domain) {
    final answer = _checkInAnswers[domain.id]; // null, 0, 1, 2

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: answer != null
              ? domain.color.withValues(alpha: 0.04)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: answer != null
                ? domain.color.withValues(alpha: 0.15)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(domain.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    domain.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              domain.question,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // 3 Antwort-Buttons: Ja / Manchmal / Noch nicht
            Row(
              children: [
                _buildAnswerChip(
                    theme, domain, 2, 'Ja', const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                _buildAnswerChip(
                    theme, domain, 1, 'Manchmal', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildAnswerChip(
                    theme, domain, 0, 'Noch nicht', const Color(0xFFEF4444)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerChip(ThemeData theme, _DevDomain domain, int value,
      String label, Color color) {
    final isSelected = _checkInAnswers[domain.id] == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _checkInAnswers[domain.id] = value;
            _checkInDone = _checkInAnswers.length >= 5;
          });
          _saveCheckIn();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Radar Chart ────────────────────────────────────────────────────────────

  Widget _buildRadarChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Euer Überblick',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _SimpleRadarPainter(
                values: _domains.map((d) {
                  final answer = _checkInAnswers[d.id] ?? 0;
                  return answer / 2.0; // 0.0 - 1.0
                }).toList(),
                colors: _domains.map((d) => d.color).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legende
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _domains.map((d) {
              final answer = _checkInAnswers[d.id] ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: d.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    d.title.split(' ').first,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Focus-Tipp (KI-Link für schwächsten Bereich) ──────────────────────────

  Widget _buildFocusTip(ThemeData theme) {
    // Finde den Bereich mit niedrigster Bewertung
    _DevDomain? weakest;
    int lowestScore = 3;
    for (final domain in _domains) {
      final score = _checkInAnswers[domain.id] ?? 2;
      if (score < lowestScore) {
        lowestScore = score;
        weakest = domain;
      }
    }

    if (weakest == null || lowestScore >= 2) {
      // Alles gut!
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            const Text('\u{2728}', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Super! Euer Kind entwickelt sich toll in allen Bereichen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              initialMessage: '___TIP_EXPAND___${weakest!.tipWhenLow}',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: weakest.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: weakest.color.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: weakest.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.lightbulb_rounded, color: weakest.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weakest.title} fördern',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Tipps von der KI: ${weakest.tipWhenLow}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: weakest.color),
          ],
        ),
      ),
    );
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

// ─── Radar Painter ────────────────────────────────────────────────────────────

class _SimpleRadarPainter extends CustomPainter {
  final List<double> values; // 0.0 - 1.0
  final List<Color> colors;

  const _SimpleRadarPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 12;
    final count = values.length;

    // Grid rings
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE2E8F0);
    for (int ring = 1; ring <= 3; ring++) {
      final r = radius * ring / 3;
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = (-90 + 360 / count * i) * math.pi / 180;
        final p = Offset(
            center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Value polygon
    final valuePath = Path();
    for (int i = 0; i < count; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final angle = (-90 + 360 / count * i) * math.pi / 180;
      final p = Offset(
        center.dx + radius * v * math.cos(angle),
        center.dy + radius * v * math.sin(angle),
      );
      i == 0 ? valuePath.moveTo(p.dx, p.dy) : valuePath.lineTo(p.dx, p.dy);
    }
    valuePath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.2);
    canvas.drawPath(valuePath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF0EA5E9);
    canvas.drawPath(valuePath, strokePaint);

    // Dots
    for (int i = 0; i < count; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final angle = (-90 + 360 / count * i) * math.pi / 180;
      final p = Offset(
        center.dx + radius * v * math.cos(angle),
        center.dy + radius * v * math.sin(angle),
      );
      canvas.drawCircle(p, 4, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleRadarPainter old) => old.values != values;
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _DevDomain {
  final String id;
  final String title;
  final String emoji;
  final String question;
  final String tipWhenLow;
  final Color color;

  const _DevDomain({
    required this.id,
    required this.title,
    required this.emoji,
    required this.question,
    required this.tipWhenLow,
    required this.color,
  });
}

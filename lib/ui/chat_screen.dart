import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/config/api_config.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/gemini_ai_service.dart';
import 'package:parentpeak/logic/pedagogical_chat_backend.dart';
import 'package:parentpeak/logic/product_metrics_service.dart';
import 'package:parentpeak/ui/calendar_screen.dart';
import 'package:parentpeak/ui/entwicklung_impulse_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _insightsStorageKey = 'ki_chat.topic_counts.v1';
  static const Map<String, List<String>> _topicKeywords = {
    'Autonomiephase': ['trotz', 'wutanfall', 'grenze', 'nein', 'auto nomi', 'rebellion', 'eigensinn'],
    'Schlaf': ['schlaf', 'einschlafen', 'durchschlafen', 'nacht', 'muede', 'müde'],
    'Konflikte': ['streit', 'konflikt', 'hauen', 'beissen', 'beißen', 'schlag', 'aggression'],
    'Schule/Kita': ['kita', 'schule', 'lehrer', 'lehrerin', 'hausaufgaben', 'lernblockade'],
    'Medien': ['handy', 'tablet', 'medien', 'bildschirm', 'youtube', 'handy sucht'],
    'Bindung & Gefühle': ['bindung', 'angst', 'trauer', 'wut', 'frustration', 'emotion', 'gefühl'],
    'Geschwister': ['geschwister', 'eifersucht', 'bruder', 'schwester', 'baby'],
    'Ernährung': ['essen', 'essstörung', 'picky', 'appetit', 'übergewicht'],
    'Krise': ['ich kann nicht mehr', 'notfall', 'gewalt', 'kontrolle verlieren', 'suizid', 'depressiv']
  };

  GeminiAIService? _geminiService;
  PedagogicalChatBackend? _chatBackend;
  final List<Map<String, dynamic>> _messages = [];
  final Map<int, String> _assistantFeedbackByIndex = {};
  final Map<String, int> _topicCounts = {};
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isStreaming = false;
  String? _initError;
  String _currentResponse = '';

  @override
  void initState() {
    super.initState();
    _loadTopicInsights();
    _initializeGemini();
  }

  Future<void> _loadTopicInsights() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_insightsStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        setState(() {
          _topicCounts
            ..clear()
            ..addAll(decoded.map((k, v) => MapEntry(k, (v as num).toInt())));
        });
      }
    } catch (e) {
      debugPrint('ChatScreen._loadTopicInsights(): ignoring corrupted local analytics data: $e');
      // Ignore corrupted local analytics data.
    }
  }

  Future<void> _persistTopicInsights() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_insightsStorageKey, jsonEncode(_topicCounts));
  }

  String _classifyTopic(String input) {
    final lower = input.toLowerCase();
    for (final entry in _topicKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Sonstiges';
  }

  Future<void> _trackTopic(String message) async {
    final topic = _classifyTopic(message);
    setState(() {
      _topicCounts[topic] = (_topicCounts[topic] ?? 0) + 1;
    });
    await _persistTopicInsights();
  }

  void _initializeGemini() {
    try {
      final apiKey = APIConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        _chatBackend = null;
        setState(() {
          _initError =
              'KI-Beratung ist aktuell nicht verfuegbar (API-Konfiguration fehlt).';
        });
        return;
      }
      _geminiService = GeminiAIService(apiKey: apiKey);
      _chatBackend = PedagogicalChatBackend(geminiService: _geminiService);
      setState(() {
        _initError = null;
      });
      debugPrint('✅ Gemini AI initialized with ${APIConfig.getGeminiModelName()}');
    } catch (e) {
      setState(() {
        _initError = 'Fehler: $e';
      });
      debugPrint('Gemini init error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isStreaming || _chatBackend == null) {
      return;
    }

    await _trackTopic(text);

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'timestamp': DateTime.now(),
      });
      _isStreaming = true;
      _currentResponse = '';
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final stream = _chatBackend!.streamReply(
        history: _messages,
        userMessage: text,
      );

      await for (final chunk in stream) {
        if (mounted) {
          setState(() {
            _currentResponse += chunk;
          });
          _scrollToBottom();
        }
      }

      if (mounted) {
        setState(() {
          if (_currentResponse.isNotEmpty) {
            _messages.add({
              'role': 'assistant',
              'content': _currentResponse,
              'timestamp': DateTime.now(),
            });
          }
          _isStreaming = false;
          _currentResponse = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStreaming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
      debugPrint('Error calling Gemini: $e');
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSuggestion(String suggestion) {
    _sendMessage(suggestion);
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _assistantFeedbackByIndex.clear();
      _currentResponse = '';
      _isStreaming = false;
    });
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chatverlauf loeschen'),
        content: const Text(
          'Moechtest du den aktuellen Chatverlauf wirklich loeschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _clearChat();
    }
  }

  void _setFeedback(int messageIndex, String value) {
    setState(() {
      _assistantFeedbackByIndex[messageIndex] = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback gespeichert: $value')),
    );
  }

  bool _isProviderUnavailableMessage(String content) {
    final lower = content.toLowerCase();
    return lower.contains('ki-beratung ist aktuell nicht verfuegbar') ||
        lower.contains('moeglicher grund:') ||
        lower.contains('debug:');
  }

  String? _findPreviousUserMessage(int assistantIndex) {
    for (var i = assistantIndex - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg['role'] == 'user') {
        final content = msg['content']?.toString();
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    }
    return null;
  }

  Future<void> _retryAssistantFailure(int assistantIndex) async {
    if (_isStreaming) {
      return;
    }
    final previousQuestion = _findPreviousUserMessage(assistantIndex);
    if (previousQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine vorherige Frage für erneuten Versuch gefunden.'),
        ),
      );
      return;
    }
    await _sendMessage(previousQuestion);
  }

  Future<void> _openDevelopmentFallback() async {
    await ProductMetricsService.instance.recordChatFallbackRouteTap(
      from: 'chat',
      to: 'development',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EntwicklungImpulseScreen(initialTabIndex: 1),
      ),
    );
  }

  Future<void> _openCalendarFallback() async {
    await ProductMetricsService.instance.recordChatFallbackRouteTap(
      from: 'chat',
      to: 'calendar',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  void _showTopicInsights() {
    final sorted = _topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MVP Themenauswertung',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Datensparsam: Es werden nur Themenzaehler gespeichert, keine Rohtexte.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (sorted.isEmpty)
                const Text('Noch keine Fragen erfasst.')
              else
                ...sorted.map(
                  (entry) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.analytics_outlined),
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    setState(_topicCounts.clear);
                    await _persistTopicInsights();
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Zaehler zuruecksetzen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8543A).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  size: 18, color: Color(0xFFE8543A)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sicher & transparent',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Keine Diagnosen, keine Therapie. Nur GfK-orientierte Orientierung nach Rosenberg. Deine Fragen bleiben privat.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF516072),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantFeedbackRow(int index) {
    final selected = _assistantFeedbackByIndex[index];
    final content = _messages[index]['content']?.toString() ?? '';
    final showRetry = _isProviderUnavailableMessage(content);
    Widget chip(String label, IconData icon) {
      final isSelected = selected == label;
      return ChoiceChip(
        selected: isSelected,
        selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFFB8C4D6).withValues(alpha: 0.9),
            width: 1.1,
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        onSelected: (_) => _setFeedback(index, label),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 8, bottom: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (showRetry)
            OutlinedButton.icon(
              onPressed: _isStreaming ? null : () => _retryAssistantFailure(index),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Erneut versuchen'),
            ),
          if (showRetry)
            OutlinedButton.icon(
              onPressed: _isStreaming ? null : _openDevelopmentFallback,
              icon: const Icon(Icons.insights_rounded, size: 16),
              label: const Text('Zu Entwicklung'),
            ),
          if (showRetry)
            OutlinedButton.icon(
              onPressed: _isStreaming ? null : _openCalendarFallback,
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('Zum Kalender'),
            ),
          chip('hilfreich', Icons.thumb_up_alt_outlined),
          chip('nicht hilfreich', Icons.thumb_down_alt_outlined),
          chip('gefaehrlich', Icons.report_gmailerrorred_rounded),
          chip('unpassend', Icons.rule_rounded),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.2),
                    const Color(0xFF0284C7).withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                size: 50,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Verlaessliche Hilfe fuer Eltern.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                color: Color(0xFF1A2A3A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hier bekommst du konkrete, paedagogisch fundierte Hilfe bei Erziehungsfragen nach Gewaltfreier Kommunikation: klar, empathisch und alltagstauglich.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                letterSpacing: 0.08,
                color: Color(0xFF516072),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8543A).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, 
                    color: Color(0xFFE8543A), 
                    size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'KI-gestützte Orientierung. Ersetzt keine professionelle Beratung oder Therapie.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF516072),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Häufige Themen:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2A3A),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Autonomiephase Tipps'),
                _buildSuggestionChip('Konflikt gewaltfrei lösen'),
                _buildSuggestionChip('Schlaftipps'),
                _buildSuggestionChip(
                    'Ich bin überfordert'),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBFD3E6),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pädagogik-KI mit Rosenberg-Fokus',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2A3A),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nur paedagogische, respektvolle und konkrete Antworten fuer Eltern.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF516072),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSuggestion(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F7FD),
            border: Border.all(
              color: const Color(0xFFB8CDE0),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F4E79),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF0284C7),
              child: Icon(
                Icons.psychology_alt_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF0284C7)
                    : const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 8),
                  bottomRight: Radius.circular(isUser ? 8 : 22),
                ),
                border: !isUser
                    ? Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isUser
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF1A2A3A))
                        .withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message['content'] as String,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  letterSpacing: 0.15,
                  color: isUser ? Colors.white : const Color(0xFF1A2A3A),
                  fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8543A),
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('KI Elternberatung'),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Themenauswertung',
              onPressed: _showTopicInsights,
              icon: const Icon(Icons.analytics_outlined),
            ),
            IconButton(
              tooltip: 'Chat loeschen',
              onPressed: _messages.isEmpty ? null : _confirmClearChat,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Du kannst trotzdem ohne Druck weitermachen:',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openDevelopmentFallback,
                      icon: const Icon(Icons.insights_rounded),
                      label: const Text('Zu Entwicklung'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openCalendarFallback,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Zum Kalender'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology_alt_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'KI Elternberatung',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Immer für dich da • GfK-orientiert',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Themenauswertung',
            onPressed: _showTopicInsights,
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(
            tooltip: 'Chat löschen',
            onPressed: _messages.isEmpty ? null : _confirmClearChat,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6FBFF),
              Color(0xFFF8FAFD),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildSafetyBanner(),
            Expanded(
              child: _messages.isEmpty && !_isStreaming
                  ? _buildEmptyState()
                  : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        final message = _messages[index];
                        final isAssistant = message['role'] == 'assistant';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMessageBubble(message),
                            if (isAssistant) _buildAssistantFeedbackRow(index),
                          ],
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.2),
                                    child: Icon(
                                      Icons.psychology,
                                      size: 18,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Schreibt...',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  backgroundColor: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
            ),
            Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE0E6ED),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isStreaming && _chatBackend != null,
                    decoration: InputDecoration(
                      hintText: 'Erzähle mir, was dich bewegt...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8A9AB0),
                        fontSize: 15,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E6ED),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E6ED),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: Color(0xFF0284C7),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      letterSpacing: 0.15,
                      color: Color(0xFF1A2A3A),
                      fontWeight: FontWeight.w500,
                    ),
                    onSubmitted: (value) {
                      _sendMessage(value);
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  backgroundColor: _isStreaming || _controller.text.isEmpty
                      ? const Color(0xFFE0E6ED)
                      : const Color(0xFF0284C7),
                  foregroundColor: _isStreaming || _controller.text.isEmpty
                      ? const Color(0xFF8A9AB0)
                      : Colors.white,
                  onPressed: _isStreaming || _controller.text.isEmpty
                      ? null
                      : () => _sendMessage(_controller.text),
                  child: _isStreaming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0284C7),
                            ),
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}

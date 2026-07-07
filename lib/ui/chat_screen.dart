import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/logic/gemini_ai_service.dart';
import 'package:trusted_circle_demo/logic/pedagogical_chat_backend.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _insightsStorageKey = 'ki_chat.topic_counts.v1';
  static const Map<String, List<String>> _topicKeywords = {
    'Trotzphase': ['trotz', 'wutanfall', 'grenze', 'nein'],
    'Schlaf': ['schlaf', 'einschlafen', 'durchschlafen', 'nacht'],
    'Konflikte': ['streit', 'konflikt', 'hauen', 'beissen', 'beißen'],
    'Schule/Kita': ['kita', 'schule', 'lehrer', 'lehrerin', 'hausaufgaben'],
    'Medien': ['handy', 'tablet', 'medien', 'bildschirm', 'youtube'],
    'Krise': ['ich kann nicht mehr', 'notfall', 'gewalt', 'kontrolle verlieren']
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KI-Transparenz und Sicherheit',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dies ist eine KI-gestuetzte Orientierung und ersetzt keine professionelle Beratung. '
            'Keine Diagnosen, keine Therapie und keine medizinische Beratung. '
            'Es werden nur datensparsame Themenzaehler fuer Produktverbesserung gespeichert.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantFeedbackRow(int index) {
    final selected = _assistantFeedbackByIndex[index];
    Widget chip(String label, IconData icon) {
      final isSelected = selected == label;
      return ChoiceChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Willkommen! 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ich bin dein KI-Beratungschat fur Elternfragen. Ich antworte padagogisch und gewaltfrei nach Rosenberg.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Dies ist eine KI-gestuetzte Orientierung und ersetzt keine professionelle Beratung.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Probiere padagogische Themen:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Trotzphase Tipps'),
                _buildSuggestionChip('Konflikt gewaltfrei losen'),
                _buildSuggestionChip('Schlaftipps'),
                _buildSuggestionChip(
                    'Ich habe Angst die Kontrolle zu verlieren'),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nur padagogische und respektvolle Antworten fur Eltern',
                    style: Theme.of(context).textTheme.bodySmall,
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
    return InputChip(
      onPressed: () => _handleSuggestion(label),
      label: Text(label),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.psychology,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message['content'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : null,
                    ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.person,
                size: 18,
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
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('KI Elternberatung'),
            const SizedBox(height: 4),
            Text(
              'Powered by ${APIConfig.getGeminiModelName()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
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
            tooltip: 'Chat loeschen',
            onPressed: _messages.isEmpty ? null : _confirmClearChat,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
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
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isStreaming && _chatBackend != null,
                    decoration: InputDecoration(
                      hintText: 'Deine Frage...',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      _sendMessage(value);
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _isStreaming || _controller.text.isEmpty
                      ? null
                      : () => _sendMessage(_controller.text),
                  child: _isStreaming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

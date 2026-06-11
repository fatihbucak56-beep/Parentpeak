import 'package:trusted_circle_demo/logic/chat_service.dart';
import 'package:trusted_circle_demo/logic/gemini_ai_service.dart';

class PedagogicalChatBackend {
  PedagogicalChatBackend({GeminiAIService? geminiService})
      : _geminiService = geminiService;

  final GeminiAIService? _geminiService;
  final ChatService _fallbackService = ChatService();

  static const List<String> _violentKeywords = [
    'schlagen',
    'hauen',
    'verletzen',
    'bestrafen',
    'demutigen',
    'gewalt',
    'toten',
    'umbringen',
    'suizid',
    'selbstmord',
    'missbrauch',
  ];

  static const List<String> _crisisKeywords = [
    'suizid',
    'selbstmord',
    'ich kann nicht mehr',
    'ich will sterben',
    'notfall',
    'akute gefahr',
    'bedroht',
    'haufige gewalt',
  ];

  static const List<String> _offTopicKeywords = [
    'bitcoin',
    'aktien',
    'programmieren',
    'flutter code',
    'hacking',
    'wahlen',
    'politik',
    'steuertrick',
  ];

  Stream<String> streamReply({
    required List<Map<String, dynamic>> history,
    required String userMessage,
  }) async* {
    final message = userMessage.trim();
    if (message.isEmpty) {
      return;
    }

    final lower = message.toLowerCase();

    if (_containsAny(lower, _crisisKeywords)) {
      yield _crisisResponse();
      return;
    }

    if (_containsAny(lower, _violentKeywords)) {
      yield _violentBoundaryResponse();
      return;
    }

    if (_containsAny(lower, _offTopicKeywords)) {
      yield _offTopicResponse();
      return;
    }

    if (_geminiService == null) {
      final fallback = await _fallbackService.sendMessage(message);
      yield fallback;
      return;
    }

    final preparedHistory = _prepareHistory(history);
    preparedHistory.add({'role': 'user', 'content': message});

    final response = await _geminiService!.chatWithHistory(preparedHistory);
    if (_containsAny(response.toLowerCase(), _violentKeywords)) {
      yield _violentBoundaryResponse();
      return;
    }

    yield response;
  }

  bool _containsAny(String input, List<String> keywords) {
    for (final keyword in keywords) {
      if (input.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  List<Map<String, String>> _prepareHistory(
      List<Map<String, dynamic>> history) {
    final prepared = <Map<String, String>>[];
    for (final item in history) {
      final role = item['role']?.toString();
      final content = item['content']?.toString();
      if (role == null || content == null || content.trim().isEmpty) {
        continue;
      }
      if (role != 'user' && role != 'assistant') {
        continue;
      }
      prepared.add({
        'role': role == 'assistant' ? 'assistant' : 'user',
        'content': content.trim(),
      });
    }
    return prepared;
  }

  String _offTopicResponse() {
    return 'Ich bin fur padagogische Elternberatung da. Wenn du magst, beschreibe deine Familien- oder Erziehungsfrage, dann unterstutze ich dich gern.';
  }

  String _violentBoundaryResponse() {
    return 'Ich kann keine gewaltfordernden oder verletzenden Anleitungen geben. '
        'Wenn du magst, helfe ich dir mit einem gewaltfreien Vorgehen nach Rosenberg: '
        '1) Beobachtung, 2) Gefuhl, 3) Bedurfnis, 4) konkrete Bitte.';
  }

  String _crisisResponse() {
    return 'Das klingt nach einer akuten Belastung. Bitte hole dir jetzt direkte Unterstutzung: '
        'In Deutschland erreichst du im Notfall den Notruf 112. '
        'Zusatzlich kann die Telefonseelsorge unter 0800 111 0 111 oder 0800 111 0 222 helfen (24/7).';
  }
}

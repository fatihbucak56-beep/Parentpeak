import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:trusted_circle_demo/config/api_config.dart';

class GeminiAIService {
  final String _modelName;
  final String? _apiKey;

  late final GenerativeModel _model;

  GeminiAIService({String? apiKey, String? modelName})
      : _apiKey = apiKey,
        _modelName = modelName ?? APIConfig.getGeminiModelName() {
    _initializeModel();
  }

  void _initializeModel() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Gemini API-Key nicht gesetzt. '
          'Bitte setze GEMINI_API_KEY als Umgebungsvariable oder übergebe ihn dem Constructor.');
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey!,
      systemInstruction: Content.text(APIConfig.parentAssistantSystemPrompt),
    );
  }

  /// Sende eine Nachricht an Gemini und erhalte einen Stream der Antwort
  Stream<String> chatWithStreaming(String userMessage) async* {
    try {
      print('DEBUG: Sende Nachricht mit Modell: $_modelName');
      print('DEBUG: API-Key Länge: ${_apiKey?.length}');

      final content = [
        Content.text(userMessage),
      ];

      final response = _model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      print('ERROR: $_modelName -> $e');
      yield 'Fehler: $e';
    }
  }

  /// Sende mehrere Nachrichten als Chat-Historie und erhalte die gesamte Antwort.
  Future<String> chatWithHistory(List<Map<String, String>> messages) async {
    try {
      final contentList = <Content>[];

      for (final msg in messages) {
        final isUser = msg['role'] == 'user';
        final roleValue = isUser ? 'user' : 'model';
        contentList.add(
          Content(roleValue, [TextPart(msg['content'] ?? '')]),
        );
      }

      final response = await _model.generateContent(contentList);
      return response.text?.trim().isNotEmpty == true
          ? response.text!.trim()
          : 'Ich bin für pädagogische Elternberatung da. Beschreibe mir gern kurz deine Situation.';
    } catch (e) {
      return 'Fehler: $e';
    }
  }

  /// Sende eine Nachricht und erhalte die komplette Antwort auf einmal
  Future<String> chat(String userMessage) async {
    try {
      final content = [
        Content.text(userMessage),
      ];

      final response = await _model.generateContent(content);

      if (response.text != null) {
        return response.text!;
      } else {
        return 'Keine Antwort erhalten.';
      }
    } catch (e) {
      return 'Fehler: $e';
    }
  }

  /// Sende mehrere Nachrichten als Chat-Historie
  Stream<String> chatWithHistoryStreaming(
    List<Map<String, String>> messages,
  ) async* {
    try {
      // Convert messages to Content objects
      final contentList = <Content>[];

      for (final msg in messages) {
        final isUser = msg['role'] == 'user';
        final roleValue = isUser ? 'user' : 'model';

        contentList.add(
          Content(roleValue, [TextPart(msg['content'] ?? '')]),
        );
      }

      final response = _model.generateContentStream(contentList);

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield 'Fehler: $e';
    }
  }
}

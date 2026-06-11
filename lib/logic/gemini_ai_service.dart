import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:trusted_circle_demo/config/api_config.dart';

class GeminiAIService {
  static const String modelName = 'gemini-2.0-flash';
  
  // System-Instruktion für Eltern-Assistent
  static const String systemInstruction = '''
Du bist ein hilfreicher Assistent für Eltern. Deine Aufgaben:

1. KINDERERZIEHUNG:
   - Gib praktische Tipps zur Erziehung
   - Unterstütze bei Trotzphasen, Schlafproblemen, etc.
   - Sei empathisch und verständnisvoll

2. FREIZEITGESTALTUNG:
   - Empfehle altersgerechte Aktivitäten
   - Gib Tipps für Familienzeit
   - Schlage Lern- und Spielmöglichkeiten vor

3. SICHERHEIT:
   - Gib Tipps zu Kinderüberwachung und Schutz
   - Warnsignale erkennen
   - Erste-Hilfe Grundlagen

4. ALLGEMEIN:
   - Sei unterstützend und nicht wertend
   - Verwende einfache, verständliche Sprache
   - Erkenne, wenn professionelle Hilfe nötig ist

Antworte immer auf Deutsch und mit praktischen, umsetzbaren Tipps.
''';

  late final GenerativeModel _model;
  String? _apiKey;

  GeminiAIService({String? apiKey}) {
    _apiKey = apiKey;
    _initializeModel();
  }

  void _initializeModel() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
        'Gemini API-Key nicht gesetzt. '
        'Bitte setze GEMINI_API_KEY als Umgebungsvariable oder übergebe ihn dem Constructor.'
      );
    }

    _model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey!,
      systemInstruction: Content.text(systemInstruction),
    );
  }

  /// Sende eine Nachricht an Gemini und erhalte einen Stream der Antwort
  Stream<String> chatWithStreaming(String userMessage) async* {
    try {
      print('DEBUG: Sende Nachricht mit Modell: $modelName');
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
      print('ERROR: $e');
      yield 'Fehler: $e';
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

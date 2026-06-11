import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfiguration für externe APIs
/// 
/// Die .env Datei wird in main.dart vor runApp() geladen:
/// await dotenv.load();

class APIConfig {
  // Gemini API Configuration - Gemini 2.0 Flash
  static const String geminiModelName = 'gemini-2.0-flash';
  
  /// Hole den Gemini API-Key aus der .env Datei oder Fallback
  /// Falls nicht gefunden, wird null zurückgegeben
  static String? getGeminiApiKey() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      print('DEBUG: GEMINI_API_KEY geladen: ${apiKey != null ? 'JA (${apiKey.substring(0, 5)}...)' : 'NEIN'}');
      if (apiKey != null && apiKey.isNotEmpty) {
        return apiKey;
      }
    } catch (e) {
      print('Fehler beim Laden von GEMINI_API_KEY: $e');
    }
    
    // Fallback: Neue API-Key mit Billing
    const fallbackKey = 'AIzaSyDZi8_TBMeQ5lze3XwJtfnNHljlPZaiKW8';
    print('DEBUG: Verwende Fallback API-Key (Gemini 2.0 Flash)');
    return fallbackKey.isNotEmpty ? fallbackKey : null;
  }

  /// Validiere ob ein API-Key vorhanden ist
  static bool isGeminiApiKeyConfigured() {
    return getGeminiApiKey() != null && getGeminiApiKey()!.isNotEmpty;
  }

  /// System-Instruktion für Eltern-Assistent
  static const String parentAssistantSystemPrompt = '''
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
Sei kurz und prägnant in deinen Antworten (max 2-3 Absätze pro Frage).
''';
}

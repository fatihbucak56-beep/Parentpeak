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
  Du bist Parentpeak Pädagogik-Beratung: ein KI-Chatbot nur für Elternfragen.

  Regeln (streng):
  1) ANTWORTBEREICH
  - Antworte nur zu Pädagogik, Erziehung, kindlicher Entwicklung, Schule/Kita, Familienkommunikation und alltagsnahen Elternfragen.
  - Bei fachfremden Themen (z.B. Technik, Finanzen, Politik, Programmierung): freundlich umleiten auf Eltern- und Pädagogikthemen.

  2) GEWALTFREIE KOMMUNIKATION (nach Marshall Rosenberg)
  - Antworte empathisch, respektvoll und deeskalierend.
  - Nutze, wenn passend, die GFK-Struktur: Beobachtung -> Gefühl -> Bedürfnis -> Bitte.
  - Keine abwertende Sprache, keine Schuldzuweisung, keine Drohungen.

  3) SICHERHEIT
  - Gib keine Anleitungen zu Gewalt, Selbstverletzung, Missbrauch oder Demütigung.
  - Bei akuter Gefahr: kurz und klar zu professioneller Hilfe raten (in Deutschland z.B. Notruf 112) und zur direkten Kontaktaufnahme mit lokalen Hilfsstellen ermutigen.

  4) STIL
  - Immer auf Deutsch.
  - Konkret, alltagsnah, umsetzbar.
  - Kurz halten (maximal 3 kurze Absätze + optional 3 Stichpunkte).
  - Keine Diagnose stellen, stattdessen pädagogische Orientierung geben.

  Wenn eine Anfrage nicht in deinen Bereich fällt, antworte freundlich mit:
  "Ich bin für pädagogische Elternberatung da. Wenn du magst, beschreibe deine Familien- oder Erziehungsfrage, dann unterstütze ich dich gern."
''';
}

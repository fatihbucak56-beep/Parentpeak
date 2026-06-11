import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfiguration für externe APIs
///
/// Die .env Datei wird in main.dart vor runApp() geladen:
/// await dotenv.load();

class APIConfig {
  // Gemini API Configuration - Gemini 2.0 Flash
  static const String geminiModelName = 'gemini-2.0-flash';

  // Backend API configuration
  static const String backendBaseUrlFallback = '';

  /// Hole den Gemini API-Key aus der .env Datei oder Fallback
  /// Falls nicht gefunden, wird null zurückgegeben
  static String? getGeminiApiKey() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      print(
          'DEBUG: GEMINI_API_KEY geladen: ${apiKey != null ? 'JA (${apiKey.substring(0, 5)}...)' : 'NEIN'}');
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

  static String? getBackendBaseUrl() {
    try {
      final value = dotenv.env['BACKEND_BASE_URL']?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } catch (_) {}

    return backendBaseUrlFallback.isNotEmpty ? backendBaseUrlFallback : null;
  }

  static String? getBackendApiToken() {
    try {
      final token = dotenv.env['BACKEND_API_TOKEN']?.trim();
      if (token != null && token.isNotEmpty) {
        return token;
      }
    } catch (_) {}
    return null;
  }

  static String getBackendFamilyId() {
    return _getEnvOrDefault('BACKEND_FAMILY_ID', 'demo-family-001');
  }

  static String getBackendApiVersion() {
    return _getEnvOrDefault('BACKEND_API_VERSION', 'v1');
  }

  static bool isBackendConfigured() {
    final baseUrl = getBackendBaseUrl();
    return baseUrl != null && baseUrl.isNotEmpty;
  }

  static String getBackendTodosPath() {
    return _getEnvOrDefault('BACKEND_TODOS_PATH', '/todos');
  }

  static String getBackendShoppingPath() {
    return _getEnvOrDefault('BACKEND_SHOPPING_PATH', '/shopping');
  }

  static String getBackendCalendarEventsPath() {
    return _getEnvOrDefault('BACKEND_CALENDAR_EVENTS_PATH', '/calendar/events');
  }

  static String getBackendHealthPath() {
    return _getEnvOrDefault('BACKEND_HEALTH_PATH', '/health');
  }

  static String _getEnvOrDefault(String key, String fallback) {
    try {
      final value = dotenv.env[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } catch (_) {}
    return fallback;
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

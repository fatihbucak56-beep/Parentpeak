import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfiguration für externe APIs
///
/// Die .env Datei wird in main.dart vor runApp() geladen:
/// await dotenv.load();

class APIConfig {
  // Gemini API Configuration - default to Gemini 3.5 Flash, overridable via .env
  static const String geminiModelName = 'gemini-3.5-flash';

  static String getGeminiModelName() {
    try {
      final modelName = dotenv.env['GEMINI_MODEL_NAME']?.trim();
      if (modelName != null && modelName.isNotEmpty) {
        return modelName;
      }
    } catch (_) {}

    return geminiModelName;
  }

  // Backend API configuration
  static const String backendBaseUrlFallback = '';

  /// Hole den Gemini API-Key aus der .env Datei.
  /// Falls nicht gefunden, wird null zurückgegeben.
  static String? getGeminiApiKey() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
      if (apiKey != null && apiKey.isNotEmpty) {
        return apiKey;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Validiere ob ein API-Key vorhanden ist
  static bool isGeminiApiKeyConfigured() {
    final apiKey = getGeminiApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Gibt fehlende Pflicht-Secrets für produktive Builds zurück.
  static List<String> getMissingRequiredSecrets() {
    final missing = <String>[];

    if (!isGeminiApiKeyConfigured()) {
      missing.add('GEMINI_API_KEY');
    }

    final backendToken = getBackendApiToken();
    if (backendToken == null || backendToken.isEmpty) {
      missing.add('BACKEND_API_TOKEN');
    }

    return missing;
  }

  /// Gibt Fehlkonfigurationen zurück, die in Release Builds blockieren sollten.
  static List<String> getReleaseConfigIssues() {
    final issues = <String>[];
    final baseUrl = getBackendBaseUrl();

    if (baseUrl == null || baseUrl.isEmpty) {
      issues.add('BACKEND_BASE_URL fehlt');
      return issues;
    }

    if (!baseUrl.startsWith('https://')) {
      issues.add('BACKEND_BASE_URL muss mit https:// beginnen');
    }

    final lower = baseUrl.toLowerCase();
    if (lower.contains('localhost') ||
        lower.contains('127.0.0.1') ||
        lower.contains('10.0.2.2')) {
      issues.add('BACKEND_BASE_URL darf kein lokaler Host sein');
    }

    return issues;
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

  static String getBackendWeeklyImpulsePath() {
    return _getEnvOrDefault(
        'BACKEND_WEEKLY_IMPULSE_PATH', '/api/weekly-impulse');
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
  Du bist die Parentpeak KI-Elternberatung.

  Ziel:
  Gib Eltern eine professionelle, pädagogisch fundierte Orientierung, die sich im Alltag sofort anwenden lässt. Antworte nicht abstrakt, nicht belehrend und nicht mit leeren Floskeln.

  Pädagogisches Leitbild (verbindlich):
  - kinderrechtsorientiert
  - gleichwuerdig
  - wissenschaftsbasiert
  - diskriminierungssensibel
  - bindungsorientiert
  - traumasensibel

  Grundsaetze:
  - Das Kind ist eine eigenstaendige Person.
  - Keine Gewalt, keine Beschaemung, keine Drohungen.
  - Eltern werden nicht verurteilt.
  - Antworten entlasten, ohne zu bagatellisieren.
  - Immer empathisch, klar und umsetzbar.
  - Keine reinen Validierungssaetze ohne naechsten Schritt.

  Sicherheitsregeln (streng):
  - Keine Diagnosen.
  - Keine Therapieanweisungen.
  - Keine medizinische Beratung oder Medikamentenempfehlung.
  - Keine Aussagen wie: "Dein Kind hat X".
  - Keine Gewaltanleitungen oder Eskalation.

  Antwortenformat:
  1) Ein kurzer, konkreter Spiegel der Situation.
  2) Zwei bis vier sofort nutzbare Schritte oder Formulierungen.
  3) Optional genau eine Rueckfrage, wenn dir noch Kontext fehlt.
  4) Wenn passend, ein wörtlicher Satz, den Eltern jetzt sagen koennen.

  Wenn die Frage vage ist, frage zuerst nach dem Wichtigsten: Alter des Kindes, Ausloeser, bisheriger Versuch und was genau jetzt am dringendsten ist.

  Krisenprotokoll:
  Wenn Hinweise auf Selbstgefaehrdung, Fremdgefaehrdung, Kindeswohlgefaehrdung,
  akute Ueberforderung oder Gewalt vorkommen:
  1) empathisch und ruhig reagieren
  2) klar benennen, dass akute menschliche Hilfe jetzt wichtig ist
  3) auf Notruf 112 sowie geeignete Hilfsangebote verweisen
  4) keine normale Langzeitberatung fortsetzen

  Stil:
  - Immer auf Deutsch.
  - Kurz, konkret, alltagsnah.
  - Maximal 3 kurze Absaetze und optional bis zu 3 Stichpunkte.
  - Gewaltfreie Kommunikation ist erwuenscht (Beobachtung, Gefuehl, Beduerfnis, Bitte).
  - Nutze klare, praxistaugliche Sprache statt allgemeiner Ratschlaege.

  Transparenzsatz, wenn passend in der Antwort:
  "Dies ist eine KI-gestuetzte Orientierung und ersetzt keine professionelle Beratung."

  Wenn die Anfrage nicht zum Bereich passt, antworte mit:
  "Ich bin fuer paedagogische Elternberatung da. Wenn du magst, beschreibe deine Familien- oder Erziehungsfrage, dann unterstuetze ich dich gern."

  Few-shot Beispiele (Antwortstil):
  Beispiel 1 - Autonomiephase/Wutanfall:
  - Wenn Eltern ueber Scham, Drohen oder Wutanfaelle berichten, antworte mit:
    1) Entlastung des Elternteils in einem Satz
    2) Einordnung: Kind sucht Regulation, nicht Machtkampf
    3) Konkreter GFK-Impuls mit Grenze ohne Beschaemung
    4) Ein Satz zum direkten Ausprobieren

  Beispiel 2 - Geschwisterkonflikt/Ueberforderung:
  - Wenn Eltern ueber Schlagen, Anschreien und Erschoepfung berichten, antworte mit:
    1) Selbstempathie fuer Eltern
    2) Beduerfnisorientierte Einordnung des Kinderverhaltens
    3) Praktische Deeskalationsschritte und gewaltfreie Konfliktbegleitung
    4) Eine klare Prioritaet fuer die naechsten 10 Minuten

  Beispiel 3 - Rote Linie/Krise:
  - Wenn Aussagen wie "ich halte das nicht mehr aus" oder Impulse gegen das Baby/Kind vorkommen:
    1) Sofortige Deeskalation und klare Sicherheitsanweisung
    2) Klare Grenze: Kind darf nicht geschaedigt werden
    3) Unmittelbare Weiterleitung an Notfall- und Hilfsstellen
    4) Keine normale Beratung fortsetzen
''';
}

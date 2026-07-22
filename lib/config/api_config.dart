import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Konfiguration für externe APIs
///
/// Die .env Datei wird in main.dart vor runApp() geladen:
/// await dotenv.load();

class APIConfig {
  // Compile-time release values (set via --dart-define).
  static const String _geminiApiKeyDefine =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _backendApiTokenDefine =
      String.fromEnvironment('BACKEND_API_TOKEN', defaultValue: '');
  static const String _backendBaseUrlDefine =
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');
  static const String _stripePublishableKeyDefine =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
  static const String _geminiModelNameDefine =
      String.fromEnvironment('GEMINI_MODEL_NAME', defaultValue: '');
  static const String _privacyPolicyUrlDefine =
      String.fromEnvironment('PRIVACY_POLICY_URL', defaultValue: '');
  static const String _termsOfServiceUrlDefine =
      String.fromEnvironment('TERMS_OF_SERVICE_URL', defaultValue: '');
  static const String _contactEmailDefine =
      String.fromEnvironment('CONTACT_EMAIL', defaultValue: '');
  static const String _contactSupportUrlDefine =
      String.fromEnvironment('CONTACT_SUPPORT_URL', defaultValue: '');

  // Gemini API Configuration - default to Gemini 3.5 Flash, overridable via env.
  static const String geminiModelName = 'gemini-3.5-flash';

  static String getGeminiModelName() {
    final modelName = _readEnvOrDefine('GEMINI_MODEL_NAME');
    if (modelName != null && modelName.isNotEmpty) {
      return modelName;
    }
    return geminiModelName;
  }

  // Backend API configuration
  static const String backendBaseUrlFallback = '';

  /// Hole den Gemini API-Key aus --dart-define oder .env.
  static String? getGeminiApiKey() {
    return _readEnvOrDefine('GEMINI_API_KEY');
  }

  /// Validiere ob ein API-Key vorhanden ist
  static bool isGeminiApiKeyConfigured() {
    final apiKey = getGeminiApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Gibt fehlende Pflicht-Secrets für produktive Builds zurück.
  static List<String> getMissingRequiredSecrets() {
    final missing = <String>[];

    // Web bundles are public. Do not require privileged tokens there.
    if (kIsWeb) {
      return missing;
    }

    if (!isGeminiApiKeyConfigured()) {
      missing.add('GEMINI_API_KEY');
    }

    return missing;
  }

  /// Gibt Fehlkonfigurationen zurück, die in Release Builds blockieren sollten.
  static List<String> getReleaseConfigIssues() {
    final issues = <String>[];
    final baseUrl = getBackendBaseUrl();
    final privacyUrl = getPrivacyPolicyUrl();
    final termsUrl = getTermsOfServiceUrl();
    final contactEmail = getContactEmail();

    if (baseUrl == null || baseUrl.isEmpty) {
      issues.add('BACKEND_BASE_URL fehlt');
    } else {
      if (!baseUrl.startsWith('https://')) {
        issues.add('BACKEND_BASE_URL muss mit https:// beginnen');
      }

      final lower = baseUrl.toLowerCase();
      if (lower.contains('localhost') ||
          lower.contains('127.0.0.1') ||
          lower.contains('10.0.2.2')) {
        issues.add('BACKEND_BASE_URL darf kein lokaler Host sein');
      }
    }

    if (privacyUrl == null || privacyUrl.isEmpty) {
      issues.add('PRIVACY_POLICY_URL fehlt');
    } else if (!privacyUrl.startsWith('https://')) {
      issues.add('PRIVACY_POLICY_URL muss mit https:// beginnen');
    }

    if (termsUrl == null || termsUrl.isEmpty) {
      issues.add('TERMS_OF_SERVICE_URL fehlt');
    } else if (!termsUrl.startsWith('https://')) {
      issues.add('TERMS_OF_SERVICE_URL muss mit https:// beginnen');
    }

    if (contactEmail == null || contactEmail.isEmpty) {
      issues.add('CONTACT_EMAIL fehlt');
    }

    return issues;
  }

  static String? getBackendBaseUrl() {
    final value = _readEnvOrDefine('BACKEND_BASE_URL');
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return backendBaseUrlFallback.isNotEmpty ? backendBaseUrlFallback : null;
  }

  static String? getBackendApiToken() {
    return _readEnvOrDefine('BACKEND_API_TOKEN');
  }

  /// Stripe publishable key — set STRIPE_PUBLISHABLE_KEY in your .env.
  /// Starts with `pk_live_` in production, `pk_test_` for testing.
  static String? getStripePublishableKey() {
    return _readEnvOrDefine('STRIPE_PUBLISHABLE_KEY');
  }

  static bool isStripePublishableKeyConfigured() {
    final key = getStripePublishableKey()?.trim();
    return key != null && key.isNotEmpty && key.startsWith('pk_');
  }

  /// Stripe PaymentSheet is currently only supported on Android and iOS.
  static bool isStripePaymentSheetSupportedPlatform() {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String getBackendFamilyId() {
    return _getEnvOrDefault('BACKEND_FAMILY_ID', 'demo-family-001');
  }

  static String getBackendProvidersPath() {
    return _getEnvOrDefault('BACKEND_PROVIDERS_PATH', '/api/providers');
  }

  static String getBackendProviderCategoriesPath() {
    return _getEnvOrDefault(
        'BACKEND_PROVIDER_CATEGORIES_PATH', '/api/categories');
  }

  static String getBackendProviderSearchPath() {
    return _getEnvOrDefault('BACKEND_PROVIDER_SEARCH_PATH', '/api/search');
  }

  static String getBackendProviderFilterPath() {
    return _getEnvOrDefault(
        'BACKEND_PROVIDER_FILTER_PATH', '/api/providers/filter');
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

  static String getBackendMealPlansPath() {
    return _getEnvOrDefault('BACKEND_MEAL_PLANS_PATH', '/meal-plans');
  }

  static String getBackendFinancePath() {
    return _getEnvOrDefault('BACKEND_FINANCE_PATH', '/finance');
  }

  static String getBackendKettenbrecherHubPath() {
    return _getEnvOrDefault(
        'BACKEND_KETTENBRECHER_HUB_PATH', '/kettenbrecher/hub');
  }

  static String getBackendKettenbrecherLocalHelpProfilesPath() {
    return _getEnvOrDefault(
      'BACKEND_KETTENBRECHER_LOCAL_HELP_PROFILES_PATH',
      '/kettenbrecher/local-help/profiles',
    );
  }

  static String getBackendKettenbrecherSosPath() {
    return _getEnvOrDefault(
        'BACKEND_KETTENBRECHER_SOS_PATH', '/kettenbrecher/sos');
  }

  static String getBackendKettenbrecherSosResponderActionPath() {
    return _getEnvOrDefault(
      'BACKEND_KETTENBRECHER_SOS_RESPONDER_ACTION_PATH',
      '/kettenbrecher/sos/responder-action',
    );
  }

  static String getBackendCommunitySnacksPath() {
    return _getEnvOrDefault(
        'BACKEND_COMMUNITY_SNACKS_PATH', '/community/snacks');
  }

  static String getBackendAudioHacksPath() {
    return _getEnvOrDefault(
        'BACKEND_AUDIO_HACKS_PATH', '/community/audio-hacks');
  }

  static String getBackendIngredientSharesPath() {
    return _getEnvOrDefault(
        'BACKEND_INGREDIENT_SHARES_PATH', '/community/ingredient-shares');
  }

  static String getBackendHealthPath() {
    return _getEnvOrDefault('BACKEND_HEALTH_PATH', '/health');
  }

  static String getBackendWeeklyImpulsePath() {
    return _getEnvOrDefault(
        'BACKEND_WEEKLY_IMPULSE_PATH', '/api/weekly-impulse');
  }

  static String getBackendPhotosPath() {
    return _getEnvOrDefault('BACKEND_PHOTOS_PATH', '/photos');
  }

  static String getBackendParentMatchingProfilesPath() {
    return _getEnvOrDefault(
      'BACKEND_PARENT_MATCHING_PROFILES_PATH',
      '/parent-matching/profiles',
    );
  }

  static String getBackendParentMatchingActionsPath() {
    return _getEnvOrDefault(
      'BACKEND_PARENT_MATCHING_ACTIONS_PATH',
      '/parent-matching/actions',
    );
  }

  static String getBackendParentMatchingConnectionsPath() {
    return _getEnvOrDefault(
      'BACKEND_PARENT_MATCHING_CONNECTIONS_PATH',
      '/parent-matching/connections',
    );
  }

  static String getBackendParentMatchingMessagesPath() {
    return _getEnvOrDefault(
      'BACKEND_PARENT_MATCHING_MESSAGES_PATH',
      '/parent-matching/messages',
    );
  }

  static String getBackendParentMatchingMyProfilePath() {
    return _getEnvOrDefault(
      'BACKEND_PARENT_MATCHING_MY_PROFILE_PATH',
      '/parent-matching/my-profile',
    );
  }

  static String getBackendParentMatchingMessagesStreamPath() {
    return _getEnvOrDefault(
      'BACKEND_PARENT_MATCHING_MESSAGES_STREAM_PATH',
      '/parent-matching/messages/stream',
    );
  }

  static String getBackendFamilyContactsPath() {
    return _getEnvOrDefault('BACKEND_FAMILY_CONTACTS_PATH', '/family/contacts');
  }

  static String getBackendFamilyRequestsPath() {
    return _getEnvOrDefault('BACKEND_FAMILY_REQUESTS_PATH', '/family/requests');
  }

  static String getBackendEventsPath() {
    return _getEnvOrDefault('BACKEND_EVENTS_PATH', '/events');
  }

  static String getBackendEventInvitationsPath() {
    return _getEnvOrDefault(
        'BACKEND_EVENT_INVITATIONS_PATH', '/events/invitations');
  }

  static String getBackendEventInvitationsJoinPath() {
    return _getEnvOrDefault(
      'BACKEND_EVENT_INVITATIONS_JOIN_PATH',
      '/events/invitations/join',
    );
  }

  static String getBackendHostedInviteOnlyEventsPath() {
    return _getEnvOrDefault(
      'BACKEND_HOSTED_INVITE_ONLY_EVENTS_PATH',
      '/events/hosted-invite-only',
    );
  }

  static String getBackendPaymentsStripeInitPath() {
    return _getEnvOrDefault(
      'BACKEND_PAYMENTS_STRIPE_INIT_PATH',
      '/payments/stripe/initiate',
    );
  }

  static String getBackendPaymentsPayPalInitPath() {
    return _getEnvOrDefault(
      'BACKEND_PAYMENTS_PAYPAL_INIT_PATH',
      '/payments/paypal/initiate',
    );
  }

  static String getBackendPaymentsConfirmPath() {
    return _getEnvOrDefault(
      'BACKEND_PAYMENTS_CONFIRM_PATH',
      '/payments/confirm',
    );
  }

  static String getBackendPaymentsProviderEventsPath() {
    return _getEnvOrDefault(
      'BACKEND_PAYMENTS_PROVIDER_EVENTS_PATH',
      '/payments/provider-events',
    );
  }

  static String getBackendPaymentsTransactionsPath() {
    return _getEnvOrDefault(
      'BACKEND_PAYMENTS_TRANSACTIONS_PATH',
      '/payments/transactions',
    );
  }

  static String getBackendPaymentsHostPath() {
    return _getEnvOrDefault(
      'BACKEND_PAYMENTS_HOST_PATH',
      '/payments/host',
    );
  }

  static String getBackendPaymentsPath() {
    return _getEnvOrDefault('BACKEND_PAYMENTS_PATH', '/payments');
  }

  static String getBackendPaymentTransactionsPath() {
    return _getEnvOrDefault(
      'BACKEND_PAYMENT_TRANSACTIONS_PATH',
      '/payments/transactions',
    );
  }

  static String getBackendAccountDeleteDataPath() {
    return _getEnvOrDefault(
      'BACKEND_ACCOUNT_DELETE_DATA_PATH',
      '/account/delete-data',
    );
  }

  static String getBackendEntitlementsPath() {
    return _getEnvOrDefault(
      'BACKEND_ENTITLEMENTS_PATH',
      '/entitlements',
    );
  }

  static String getBackendEntitlementsActivatePremiumSuffix() {
    return _getEnvOrDefault(
      'BACKEND_ENTITLEMENTS_ACTIVATE_PREMIUM_SUFFIX',
      '/activate-premium',
    );
  }

  // ──  Legal & Compliance URLs ──────────────────────────────────────────────

  /// Privacy Policy URL (required for stores)
  static String? getPrivacyPolicyUrl() {
    return _getEnvOrDefault('PRIVACY_POLICY_URL', '');
  }

  /// Terms of Service URL (required for stores)
  static String? getTermsOfServiceUrl() {
    return _getEnvOrDefault('TERMS_OF_SERVICE_URL', '');
  }

  /// Support/Contact Email
  static String? getContactEmail() {
    return _getEnvOrDefault('CONTACT_EMAIL', '');
  }

  /// Support/Contact URL
  static String? getContactSupportUrl() {
    return _getEnvOrDefault('CONTACT_SUPPORT_URL', '');
  }

  static String _getEnvOrDefault(String key, String fallback) {
    final value = _readEnvOrDefine(key);
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  static String? _readEnvOrDefine(String key) {
    try {
      final envValue = dotenv.env[key]?.trim();
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    } catch (e) {
      final message = e.toString();
      if (!message.contains('NotInitializedError')) {
        debugPrint(
            'APIConfig._readEnvOrDefine(): dotenv read failed for $key: $e');
      }
    }

    final compileTimeValue = _readCompileTimeValue(key);
    if (compileTimeValue != null && compileTimeValue.isNotEmpty) {
      return compileTimeValue;
    }

    return null;
  }

  static String? _readCompileTimeValue(String key) {
    switch (key) {
      case 'GEMINI_API_KEY':
        return _geminiApiKeyDefine.isNotEmpty ? _geminiApiKeyDefine : null;
      case 'BACKEND_API_TOKEN':
        return _backendApiTokenDefine.isNotEmpty
            ? _backendApiTokenDefine
            : null;
      case 'BACKEND_BASE_URL':
        return _backendBaseUrlDefine.isNotEmpty ? _backendBaseUrlDefine : null;
      case 'STRIPE_PUBLISHABLE_KEY':
        return _stripePublishableKeyDefine.isNotEmpty
            ? _stripePublishableKeyDefine
            : null;
      case 'GEMINI_MODEL_NAME':
        return _geminiModelNameDefine.isNotEmpty
            ? _geminiModelNameDefine
            : null;
      case 'PRIVACY_POLICY_URL':
        return _privacyPolicyUrlDefine.isNotEmpty
            ? _privacyPolicyUrlDefine
            : null;
      case 'TERMS_OF_SERVICE_URL':
        return _termsOfServiceUrlDefine.isNotEmpty
            ? _termsOfServiceUrlDefine
            : null;
      case 'CONTACT_EMAIL':
        return _contactEmailDefine.isNotEmpty ? _contactEmailDefine : null;
      case 'CONTACT_SUPPORT_URL':
        return _contactSupportUrlDefine.isNotEmpty
            ? _contactSupportUrlDefine
            : null;
      default:
        return null;
    }
  }

  /// System-Instruktion für Eltern-Assistent
  static const String parentAssistantSystemPrompt = '''
Du bist der ParentPeak Eltern-Coach — eine warmherzige, kluge Begleitung für Eltern im Alltag mit Kindern (0–18 Jahre).

Du bist ANDERS als andere Chatbots:
- Du gibst keine langen Textwände.
- Du moralisierst nie.
- Du gibst Eltern das Gefühl: "Ich schaffe das."
- Du sprichst wie eine erfahrene beste Freundin die auch Pädagogin ist.

═══════════════════════════════════════════════
DEINE ANTWORT-STRUKTUR (IMMER so, keine Ausnahme):
═══════════════════════════════════════════════

Jede Antwort hat GENAU diese 4 Teile. Nutze die Emojis als Überschriften:

❤️ ERSTMAL FÜR DICH
Ein einziger Satz der dem Elternteil zeigt: Ich sehe dich. Du bist nicht schuld. Das ist schwer UND normal.
(Maximal 2 Sätze. Kurz. Warm. Echt.)

🧒 WAS DEIN KIND DIR SAGEN WILL
Übersetze das Verhalten des Kindes in 1-2 Sätze aus Kinderperspektive.
Schreibe es so, als würde das Kind es selbst sagen können:
"Mama/Papa, ich brauche..." oder "Ich fühle mich..."
(Das hilft Eltern sofort das Verhalten anders zu sehen)

🗣️ DAS KANNST DU SAGEN
Gib EINEN konkreten Satz den das Elternteil direkt so zum Kind sagen kann.
In Anführungszeichen. Altersgerecht formuliert.
Danach optional: Ein Alternativ-Satz für wenn der erste nicht passt.

🎯 DEIN NÄCHSTER SCHRITT
Genau EINE konkrete Aktion. Nicht 5. Nicht 3. EINE.
Formuliere sie als: "In den nächsten 5 Minuten: ..."
Oder: "Heute Abend: ..."
Oder: "Morgen früh als erstes: ..."
(Zeitlich verankert = umsetzbar)

═══════════════════════════════════════════════
DEINE REGELN (nicht verhandelbar):
═══════════════════════════════════════════════

TONFALL:
- Duze immer. Warm, direkt, auf Augenhöhe.
- Maximal 8-10 Zeilen pro Abschnitt. Kürzer ist besser.
- Schreibe für Smartphone-Screens (kurze Absätze, Luft dazwischen).
- Keine Fachbegriffe ohne Erklärung.
- Kein "Man sollte...", nur "Du kannst..."

PÄDAGOGIK:
- Gewaltfreie Kommunikation nach Rosenberg (Gefühle + Bedürfnisse)
- Beziehungsorientiert nach Jesper Juul (Führung ohne Gewalt)
- Kind ist nie "böse" oder "manipulativ"
- Grenzen setzen = ja. Strafen/Drohungen/Beschämung = nie.
- Eltern sind nie "falsch". Sie brauchen Werkzeuge, nicht Vorwürfe.

VERBOTEN:
- Keine Diagnosen (ADHS, Autismus etc.)
- Keine medizinischen Ratschläge
- Niemals einen Disclaimer anhängen
- Keine Textwände (>15 Zeilen pro Abschnitt = zu lang)
- Nicht "Das ist ganz normal" ohne konkreten nächsten Schritt

SICHERHEIT:
Bei akuter Gefahr (Gewalt, Suizid, Misshandlung):
→ Sofort: Notruf 112, Telefonseelsorge 0800-1110111, Jugendamt
→ Keine normale Beratung fortsetzen.

═══════════════════════════════════════════════
WENN DAS ALTER FEHLT:
═══════════════════════════════════════════════

Frage am Ende freundlich: "Wie alt ist dein Kind? Dann kann ich noch genauer helfen."
Antworte trotzdem mit einer allgemeinen Version.

═══════════════════════════════════════════════
BEISPIEL (so soll es aussehen):
═══════════════════════════════════════════════

Frage: "Mein Kind schreit immer beim Anziehen morgens"

❤️ ERSTMAL FÜR DICH
Morgens unter Zeitdruck und ein schreiendes Kind — das ist einer der härtesten Momente. Du bist nicht die Einzige.

🧒 WAS DEIN KIND DIR SAGEN WILL
"Mama, ich war noch nicht fertig mit meiner Welt. Ich brauche eine Sekunde Übergang, bevor alles losgeht."

🗣️ DAS KANNST DU SAGEN
"Hey, ich sehe du bist noch nicht bereit. Wir müssen gleich los — magst du mit dem Oberteil oder der Hose anfangen?"

🎯 DEIN NÄCHSTER SCHRITT
Morgen früh: Weck dein Kind 3 Minuten früher und setz dich kurz zu ihm, bevor du sagst was passiert. Diese 3 Minuten Verbindung ändern den ganzen Morgen.
''';
}

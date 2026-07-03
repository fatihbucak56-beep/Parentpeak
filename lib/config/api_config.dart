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
    return _getEnvOrDefault('BACKEND_PROVIDER_CATEGORIES_PATH', '/api/categories');
  }

  static String getBackendProviderSearchPath() {
    return _getEnvOrDefault('BACKEND_PROVIDER_SEARCH_PATH', '/api/search');
  }

  static String getBackendProviderFilterPath() {
    return _getEnvOrDefault('BACKEND_PROVIDER_FILTER_PATH', '/api/providers/filter');
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
    return _getEnvOrDefault('BACKEND_KETTENBRECHER_HUB_PATH', '/kettenbrecher/hub');
  }

  static String getBackendKettenbrecherLocalHelpProfilesPath() {
    return _getEnvOrDefault(
      'BACKEND_KETTENBRECHER_LOCAL_HELP_PROFILES_PATH',
      '/kettenbrecher/local-help/profiles',
    );
  }

  static String getBackendKettenbrecherSosPath() {
    return _getEnvOrDefault('BACKEND_KETTENBRECHER_SOS_PATH', '/kettenbrecher/sos');
  }

  static String getBackendKettenbrecherSosResponderActionPath() {
    return _getEnvOrDefault(
      'BACKEND_KETTENBRECHER_SOS_RESPONDER_ACTION_PATH',
      '/kettenbrecher/sos/responder-action',
    );
  }

  static String getBackendCommunitySnacksPath() {
    return _getEnvOrDefault('BACKEND_COMMUNITY_SNACKS_PATH', '/community/snacks');
  }

  static String getBackendAudioHacksPath() {
    return _getEnvOrDefault('BACKEND_AUDIO_HACKS_PATH', '/community/audio-hacks');
  }

  static String getBackendIngredientSharesPath() {
    return _getEnvOrDefault('BACKEND_INGREDIENT_SHARES_PATH', '/community/ingredient-shares');
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
    return _getEnvOrDefault('BACKEND_EVENT_INVITATIONS_PATH', '/events/invitations');
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
    final compileTimeValue = _readCompileTimeValue(key);
    if (compileTimeValue != null && compileTimeValue.isNotEmpty) {
      return compileTimeValue;
    }

    try {
      final envValue = dotenv.env[key]?.trim();
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    } catch (e) {
      final message = e.toString();
      if (!message.contains('NotInitializedError')) {
        debugPrint('APIConfig._readEnvOrDefine(): dotenv read failed for $key: $e');
      }
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
        return _privacyPolicyUrlDefine.isNotEmpty ? _privacyPolicyUrlDefine : null;
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

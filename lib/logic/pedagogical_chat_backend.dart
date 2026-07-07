import 'package:flutter/foundation.dart';
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
    'toten',
    'umbringen',
    'suizid',
    'selbstmord',
    'missbrauch',
  ];

  static const List<String> _harmfulIntentKeywords = [
    'wie schlage ich',
    'wie haue ich',
    'wie bestrafe ich',
    'wie kann ich meinem kind wehtun',
    'ich will meinem kind wehtun',
    'ich will es verletzen',
    'ich will ihn verletzen',
    'ich will sie verletzen',
    'ich will schlagen',
    'anleitung fuer',
    'anleitung für',
    'tipps zum schlagen',
  ];

  static const List<String> _helpSeekingViolenceContextKeywords = [
    'gewaltfrei',
    'ohne gewalt',
    'deeskalation',
    'konflikt loesen',
    'konflikt lösen',
    'mein kind schlaegt',
    'mein kind schlägt',
    'meine kinder schlagen sich',
    'geschwisterkonflikt',
    'ich will nicht schlagen',
    'ich moechte nicht schreien',
    'ich möchte nicht schreien',
    'wie beruhige ich',
    'wie begleite ich',
  ];

  static const List<String> _nonViolentContextKeywords = [
    'gewaltfrei',
    'gewaltfreie',
    'gewaltfreien',
    'ohne gewalt',
    'gegen gewalt',
    'deeskalation',
  ];

  static const List<String> _crisisKeywords = [
    'suizid',
    'selbstmord',
    'ich kann nicht mehr',
    'ich halte es nicht mehr aus',
    'ich will sterben',
    'ich will verschwinden',
    'ich koennte meinem kind etwas antun',
    'ich könnte meinem kind etwas antun',
    'ich habe angst die kontrolle zu verlieren',
    'mein partner schlaegt das kind',
    'mein partner schlägt das kind',
    'notfall',
    'akute gefahr',
    'bedroht',
    'haufige gewalt',
    'haeufige gewalt',
    'kindeswohlgefaehrdung',
    'kindeswohlgefährdung',
    'selbstverletzung',
    'fremdgefaehrdung',
    'fremdgefährdung',
  ];

  static const List<String> _diagnosisKeywords = [
    'diagnose',
    'adhs',
    'autismus',
    'depression',
    'ptbs',
    'störung',
    'stoerung',
    'krankheit',
    'hat mein kind',
  ];

  static const List<String> _medicalKeywords = [
    'medikament',
    'dosis',
    'tablette',
    'fieber',
    'arztbrief',
    'rezept',
    'antibiotika',
    'therapieplan',
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

    if (_containsAny(lower, _diagnosisKeywords)) {
      yield _diagnosisBoundaryResponse();
      return;
    }

    if (_containsAny(lower, _medicalKeywords)) {
      yield _medicalBoundaryResponse();
      return;
    }

    if (_shouldBlockViolenceIntent(lower)) {
      yield _violentBoundaryResponse();
      return;
    }

    if (_containsAny(lower, _offTopicKeywords)) {
      yield _offTopicResponse();
      return;
    }

    if (_geminiService == null) {
      if (kDebugMode) {
        final fallback = await _fallbackService.sendMessage(message);
        yield fallback;
      } else {
        yield _providerUnavailableResponse();
      }
      return;
    }

    final preparedHistory = _prepareHistory(history);
    preparedHistory.add({'role': 'user', 'content': message});

    final response = await _geminiService!.chatWithHistory(preparedHistory);
    if (_looksLikeProviderError(response)) {
      if (kDebugMode) {
        final fallback = await _fallbackService.sendMessage(message);
        yield fallback;
      } else {
        yield _providerUnavailableResponse();
      }
      return;
    }
    if (_containsAny(response.toLowerCase(), _diagnosisKeywords)) {
      yield _diagnosisBoundaryResponse();
      return;
    }
    if (_containsAny(response.toLowerCase(), _medicalKeywords)) {
      yield _medicalBoundaryResponse();
      return;
    }
    if (_shouldBlockViolenceIntent(response.toLowerCase())) {
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

  bool _looksLikeProviderError(String input) {
    final lower = input.toLowerCase();
    const markers = [
      'fehler:',
      'quota exceeded',
      'exceeded your current quota',
      'rate-limit',
      'rate limit',
      'resource has been exhausted',
      'generate_content_free_tier',
      'billing details',
      'api key',
      '429',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) {
        return true;
      }
    }
    return false;
  }

  bool _shouldBlockViolenceIntent(String input) {
    final hasViolenceTerms = _containsAny(input, _violentKeywords);
    if (!hasViolenceTerms) return false;

    final hasSafeContext = _containsAny(input, _nonViolentContextKeywords) ||
        _containsAny(input, _helpSeekingViolenceContextKeywords);
    if (hasSafeContext) return false;

    return _containsAny(input, _harmfulIntentKeywords);
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

  String _diagnosisBoundaryResponse() {
    return 'Ich kann keine Diagnose stellen oder bestaetigen, was ein Kind "hat". '
        'Ich kann dir aber paedagogische Orientierung geben, wie du dein Kind im Alltag stabil und bindungsorientiert begleiten kannst. '
        'Wenn du diagnostische Klaerung brauchst, wende dich bitte an Kinderarztpraxis oder Kinder- und Jugendpsychologie.';
  }

  String _medicalBoundaryResponse() {
    return 'Ich gebe keine medizinischen Empfehlungen oder Medikamentenhinweise. '
        'Bei gesundheitlichen Fragen nutze bitte aerztliche Beratung. '
        'Bei Unsicherheit ausserhalb der Sprechzeiten hilft in Deutschland der aerztliche Bereitschaftsdienst unter 116117.';
  }

  String _crisisResponse() {
    return 'Das klingt nach einer akuten Belastung. Du musst damit nicht allein bleiben. '
        'Dies ist eine KI-gestuetzte Orientierung und ersetzt keine professionelle Beratung. '
        'Bitte hole jetzt direkte menschliche Hilfe: '
        'Im Notfall 112, Telefonseelsorge 0800 111 0 111 oder 0800 111 0 222 (24/7), '
        'bei medizinischer Dringlichkeit 116117 und bei Kindeswohlgefaehrdung das zustaendige Jugendamt.';
  }

  String _providerUnavailableResponse() {
    return 'Die KI-Beratung ist aktuell nicht verfuegbar. '
        'Bitte versuche es spaeter erneut oder kontaktiere den Support, falls das Problem bestehen bleibt.';
  }
}

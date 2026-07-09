import 'package:trusted_circle_demo/logic/gemini_ai_service.dart';

class PedagogicalChatBackend {
  PedagogicalChatBackend({GeminiAIService? geminiService})
      : _geminiService = geminiService;

  final GeminiAIService? _geminiService;

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

  static const List<String> _diagnosisIntentKeywords = [
    'diagnose',
    'hat mein kind',
    'ist das adhs',
    'ist es adhs',
    'hat er adhs',
    'hat sie adhs',
    'hat mein kind autismus',
    'ist mein kind autistisch',
    'hat mein kind depression',
  ];

  static const List<String> _medicalTreatmentIntentKeywords = [
    'medikament',
    'dosis',
    'tablette',
    'rezept',
    'antibiotika',
    'therapieplan',
    'wie viel',
    'wie oft geben',
    'einnahme',
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

  static const Map<String, List<String>> _topicModeKeywords = {
    'Trotz und Wut': [
      'trotz',
      'wutanfall',
      'ausrasten',
      'schreit',
      'schreien',
      'nein',
    ],
    'Geschwisterkonflikt': [
      'geschwister',
      'streit',
      'konflikt',
      'hauen',
      'beißen',
      'beissen',
    ],
    'Schlaf': [
      'schlaf',
      'einschlafen',
      'durchschlafen',
      'nacht',
    ],
    'Medien': [
      'medien',
      'handy',
      'tablet',
      'youtube',
      'bildschirm',
    ],
    'Kita und Schule': [
      'kita',
      'schule',
      'lehrer',
      'lehrerin',
      'hausaufgaben',
    ],
  };

  static const List<String> _forbiddenResponseMarkers = [
    'schrei',
    'anschreien',
    'droh',
    'drohen',
    'bescham',
    'beschäm',
    'bloßstell',
    'strafe',
    'bestrafe',
    'demuetig',
    'demütig',
    'ignorier dein kind',
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

    if (_containsAny(lower, _diagnosisIntentKeywords)) {
      yield _diagnosisBoundaryResponse();
      return;
    }

    if (_containsAny(lower, _medicalTreatmentIntentKeywords)) {
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
      yield _providerUnavailableResponse();
      return;
    }

    final topicMode = _classifyTopicMode(lower);
    final preparedHistory = _prepareHistory(history);
    final needsFollowUpQuestion = _shouldAskSingleFollowUpQuestion(message);
    final coachingPrompt = _buildCoachingPrompt(
      userMessage: message,
      topicMode: topicMode,
      needsFollowUpQuestion: needsFollowUpQuestion,
    );
    preparedHistory.add({'role': 'user', 'content': coachingPrompt});

    var response = await _geminiService!.chatWithHistory(preparedHistory);
    if (_looksLikeProviderError(response)) {
      yield _providerUnavailableResponse();
      return;
    }

    if (_needsQualityRetry(response)) {
      final retryHistory = List<Map<String, String>>.from(preparedHistory)
        ..add({'role': 'assistant', 'content': response})
        ..add({'role': 'user', 'content': _qualityRetryInstruction(topicMode)});
      final retryResponse = await _geminiService!.chatWithHistory(retryHistory);
      if (!_looksLikeProviderError(retryResponse) && retryResponse.trim().isNotEmpty) {
        response = retryResponse;
      }
    }

    if (_containsAny(response.toLowerCase(), _diagnosisIntentKeywords)) {
      yield _diagnosisBoundaryResponse();
      return;
    }
    if (_containsAny(response.toLowerCase(), _medicalTreatmentIntentKeywords)) {
      yield _medicalBoundaryResponse();
      return;
    }
    if (_shouldBlockViolenceIntent(response.toLowerCase())) {
      yield _violentBoundaryResponse();
      return;
    }

    if (_violatesCorePedagogicalValues(response.toLowerCase())) {
      yield _coreValuesBoundaryResponse();
      return;
    }

    yield response;
  }

  String _classifyTopicMode(String lowerInput) {
    for (final entry in _topicModeKeywords.entries) {
      if (_containsAny(lowerInput, entry.value)) {
        return entry.key;
      }
    }
    return 'Allgemeine Elternfrage';
  }

  bool _shouldAskSingleFollowUpQuestion(String message) {
    final compact = message.trim();
    if (compact.length < 24) {
      return true;
    }

    final lower = compact.toLowerCase();
    final hasAge = RegExp(r'\b\d{1,2}\b').hasMatch(lower) ||
        lower.contains('jahr') ||
        lower.contains('monate') ||
        lower.contains('kindergartenalter') ||
        lower.contains('grundschule');
    final hasTriggerContext = lower.contains('weil') ||
        lower.contains('wenn') ||
        lower.contains('situation') ||
        lower.contains('passiert');

    return !hasAge || !hasTriggerContext;
  }

  String _buildCoachingPrompt({
    required String userMessage,
    required String topicMode,
    required bool needsFollowUpQuestion,
  }) {
    final modeHint = _modeSpecificHint(topicMode);
    final followUpRule = needsFollowUpQuestion
        ? 'Stelle am Ende genau EINE kurze Rueckfrage, die den naechsten hilfreichen Schritt absichert.'
        : 'Stelle keine Rueckfrage, wenn die Lage fuer konkrete Schritte ausreicht.';

    return '''
Themenmodus: $topicMode

Nutzeranliegen:
$userMessage

Antworte als paedagogischer GFK-Experte mit diesem Pflichtformat:
1) Kurze, entlastende Spiegelung der Lage.
2) GFK-Einordnung (Beobachtung, Gefuehl, Beduerfnis).
3) 2 bis 4 konkrete naechste Schritte fuer die naechsten 24 Stunden.
4) Zwei wortwoertliche Beispielsatz-Formulierungen fuer Eltern.
5) $followUpRule

Modus-Hinweis:
$modeHint

Wichtig:
- Kein Moralisieren.
- Keine leeren Floskeln.
- Kein abstrakter Theorieblock.
- Klar, waermend, handlungsfaehig.
''';
  }

  String _modeSpecificHint(String topicMode) {
    switch (topicMode) {
      case 'Trotz und Wut':
        return 'Fokus auf Co-Regulation, klare Grenzen ohne Beschaemung und kurze Deeskalation im Moment.';
      case 'Geschwisterkonflikt':
        return 'Fokus auf Trennen ohne Strafe, Gefuehle spiegeln, faire Wiederannaeherung und Wiedergutmachung.';
      case 'Schlaf':
        return 'Fokus auf realistische Entlastung, kleine Routinen und energiesparende Schritte fuer Eltern.';
      case 'Medien':
        return 'Fokus auf klare, vorab vereinbarte Grenzen plus kooperative Uebergaenge statt Machtkampf.';
      case 'Kita und Schule':
        return 'Fokus auf kindgerechte Begleitung, alltagsnahe Struktur und kooperative Kommunikation mit Fachkraeften.';
      default:
        return 'Fokus auf eine sofort umsetzbare, bindungsorientierte Entlastung fuer den Familienalltag.';
    }
  }

  bool _needsQualityRetry(String response) {
    final lower = response.toLowerCase();
    if (response.trim().length < 180) {
      return true;
    }
    const genericMarkers = [
      'als ki',
      'ich kann dir leider nur',
      'es kommt darauf an',
      'das ist individuell',
    ];
    return _containsAny(lower, genericMarkers);
  }

  String _qualityRetryInstruction(String topicMode) {
    return 'Bitte antworte jetzt deutlich konkreter fuer den Modus "$topicMode": '
      'maximal 4 kurze Abschnitte, alltagsnahe Schritte, zwei direkte Beispielsaetze, '
        'keine Allgemeinplaetze.';
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

  bool _violatesCorePedagogicalValues(String responseLower) {
    if (!_containsAny(responseLower, _forbiddenResponseMarkers)) {
      return false;
    }
    return _containsDirectiveLanguage(responseLower);
  }

  bool _containsDirectiveLanguage(String input) {
    const directiveMarkers = [
      'du solltest',
      'du musst',
      'mach ',
      'mache ',
      'sag ihm',
      'sag ihr',
      'tu so',
      'ignoriere',
    ];
    return _containsAny(input, directiveMarkers);
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

  String _coreValuesBoundaryResponse() {
    return 'Ich bleibe bei gewaltfreier, kinderechtsorientierter und bindungsorientierter Begleitung. '
        'Ich gebe daher keine Ratschlaege zu Beschaemung, Drohungen oder Strafe. '
        'Wenn du magst, formuliere ich dir stattdessen eine konkrete Alternative nach GFK: '
        '1) Beobachtung, 2) Gefuehl, 3) Beduerfnis, 4) Bitte.';
  }
}

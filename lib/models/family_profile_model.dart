import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Familien-Profil fuer "Spielfreunde finden".
class FamilyMatchProfile {
  final String displayName; // Vorname + Anfangsbuchstabe
  final String district; // Stadtteil / PLZ
  final List<ChildEntry> children;
  final List<String> languages; // de, tr, ar, ku, en...
  final String familyForm; // kernfamilie, alleinerziehend, patchwork, regenbogen, gross
  final List<String> values; // beduerfnisorientiert, montessori, waldorf, freilernend, strukturiert
  final List<String> lookingFor; // spielplatz, kochen, sport, natur, kreativ, regelmaessig
  final String availability; // vormittags, nachmittags, wochenende, flexibel
  final List<String> specials; // behinderung, neurodivergent, fruehchen, mehrlinge
  final String bio; // max 140 Zeichen
  final bool hasPhoto;
  final DateTime createdAt;

  const FamilyMatchProfile({
    required this.displayName,
    required this.district,
    required this.children,
    required this.languages,
    required this.familyForm,
    required this.values,
    required this.lookingFor,
    required this.availability,
    this.specials = const [],
    this.bio = '',
    this.hasPhoto = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'district': district,
    'children': children.map((c) => c.toJson()).toList(),
    'languages': languages,
    'familyForm': familyForm,
    'values': values,
    'lookingFor': lookingFor,
    'availability': availability,
    'specials': specials,
    'bio': bio,
    'hasPhoto': hasPhoto,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FamilyMatchProfile.fromJson(Map<String, dynamic> j) => FamilyMatchProfile(
    displayName: j['displayName'] ?? '',
    district: j['district'] ?? '',
    children: ((j['children'] as List?) ?? []).map((c) => ChildEntry.fromJson(c)).toList(),
    languages: List<String>.from(j['languages'] ?? []),
    familyForm: j['familyForm'] ?? '',
    values: List<String>.from(j['values'] ?? []),
    lookingFor: List<String>.from(j['lookingFor'] ?? []),
    availability: j['availability'] ?? 'flexibel',
    specials: List<String>.from(j['specials'] ?? []),
    bio: j['bio'] ?? '',
    hasPhoto: j['hasPhoto'] ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  static Future<FamilyMatchProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('spielfreunde.profile');
    if (raw == null || raw.isEmpty) return null;
    try { return FamilyMatchProfile.fromJson(jsonDecode(raw)); } catch (_) { return null; }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spielfreunde.profile', jsonEncode(toJson()));
  }
}

class ChildEntry {
  final String name;
  final int age;
  final List<String> interests; // spielplatz, basteln, natur, sport, musik, tiere

  const ChildEntry({required this.name, required this.age, this.interests = const []});

  Map<String, dynamic> toJson() => {'name': name, 'age': age, 'interests': interests};
  factory ChildEntry.fromJson(Map<String, dynamic> j) => ChildEntry(
    name: j['name'] ?? '', age: j['age'] ?? 0, interests: List<String>.from(j['interests'] ?? []));
}

/// Vordefinierte Optionen.
class MatchOptions {
  static const List<String> familyForms = ['kernfamilie', 'alleinerziehend', 'patchwork', 'regenbogen', 'grossfamilie'];
  static const Map<String, String> familyFormLabels = {'kernfamilie': 'Kernfamilie', 'alleinerziehend': 'Alleinerziehend', 'patchwork': 'Patchwork', 'regenbogen': 'Regenbogenfamilie', 'grossfamilie': 'Grossfamilie'};

  static const List<String> valueOptions = ['beduerfnisorientiert', 'montessori', 'waldorf', 'freilernend', 'strukturiert', 'religioes', 'offen'];
  static const Map<String, String> valueLabels = {'beduerfnisorientiert': 'Beduerfnisorientiert', 'montessori': 'Montessori', 'waldorf': 'Waldorf', 'freilernend': 'Freilernend', 'strukturiert': 'Strukturiert', 'religioes': 'Religioes', 'offen': 'Offen fuer alles'};

  static const List<String> lookingForOptions = ['spielplatz', 'kochen', 'sport', 'natur', 'kreativ', 'regelmaessig', 'spontan'];
  static const Map<String, String> lookingForLabels = {'spielplatz': 'Spielplatz-Dates', 'kochen': 'Gemeinsam kochen', 'sport': 'Sport & Bewegung', 'natur': 'Wald & Natur', 'kreativ': 'Kreativ-Treffen', 'regelmaessig': 'Regelmaessige Gruppe', 'spontan': 'Spontane Treffen'};

  static const List<String> availOptions = ['vormittags', 'nachmittags', 'wochenende', 'flexibel'];
  static const Map<String, String> availLabels = {'vormittags': 'Vormittags', 'nachmittags': 'Nachmittags', 'wochenende': 'Wochenende', 'flexibel': 'Flexibel'};

  static const List<String> specialOptions = ['behinderung', 'neurodivergent', 'fruehchen', 'mehrlinge'];
  static const Map<String, String> specialLabels = {'behinderung': 'Kind mit Behinderung', 'neurodivergent': 'Neurodivergent', 'fruehchen': 'Fruehchen-Eltern', 'mehrlinge': 'Mehrlinge'};

  static const List<String> childInterests = ['spielplatz', 'basteln', 'natur', 'sport', 'musik', 'tiere', 'buecher', 'bauen'];
  static const Map<String, String> childInterestLabels = {'spielplatz': 'Spielplatz', 'basteln': 'Basteln', 'natur': 'Natur', 'sport': 'Sport', 'musik': 'Musik', 'tiere': 'Tiere', 'buecher': 'Buecher', 'bauen': 'Bauen & Konstruieren'};

  static const Map<String, String> languageLabels = {'de': 'Deutsch', 'en': 'English', 'tr': 'Tuerkisch', 'ar': 'Arabisch', 'ku': 'Kurdisch', 'fr': 'Franzoesisch', 'es': 'Spanisch', 'ru': 'Russisch', 'pl': 'Polnisch', 'it': 'Italienisch'};
}

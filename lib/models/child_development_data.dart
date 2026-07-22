import 'package:flutter/material.dart';

/// Kind-Profil für die Entwicklungseinschätzung.
class ChildProfile {
  final String name;
  final DateTime birthDate;
  final String careType; // 'kita', 'tagesmutter', 'zuhause', 'andere'

  const ChildProfile({
    required this.name,
    required this.birthDate,
    required this.careType,
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  }

  String get ageLabel {
    final months = ageInMonths;
    if (months < 12) return '$months Monate';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years Jahre';
    return '$years Jahre, $remainingMonths Monate';
  }

  String get ageGroupId {
    final months = ageInMonths;
    if (months < 12) return '0-12m';
    if (months < 24) return '1-2y';
    if (months < 36) return '2-3y';
    if (months < 48) return '3-4y';
    if (months < 72) return '4-6y';
    if (months < 120) return '6-10y';
    if (months < 168) return '10-14y';
    return '14-18y';
  }

  Map<String, String> toJson() => {
    'name': name,
    'birthDate': birthDate.toIso8601String(),
    'careType': careType,
  };

  factory ChildProfile.fromJson(Map<String, String> json) => ChildProfile(
    name: json['name'] ?? '',
    birthDate: DateTime.tryParse(json['birthDate'] ?? '') ?? DateTime.now(),
    careType: json['careType'] ?? 'zuhause',
  );
}

/// Ein Entwicklungsbereich mit Fragen.
class DevDomain {
  final String id;
  final String title;
  final String emoji;
  final Color color;
  final String description;
  final List<String> questions;
  final List<String> tips;

  const DevDomain({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
    required this.description,
    required this.questions,
    required this.tips,
  });
}

/// Altersgerechte Fragesets.
/// Pilot: 2-3 Jahre (30 Fragen, 5 Bereiche × 6 Fragen)
class DevelopmentQuestionBank {
  static List<DevDomain> getQuestionsForAge(String ageGroupId) {
    switch (ageGroupId) {
      case '2-3y':
        return _questions2to3;
      default:
        return _questions2to3; // Fallback auf Pilot
    }
  }

  static const List<DevDomain> _questions2to3 = [
    DevDomain(
      id: 'motorik',
      title: 'Bewegung & Koerper',
      emoji: '\u{1F3C3}',
      color: Color(0xFF0EA5E9),
      description: 'Grobmotorik, Feinmotorik & Koerperwahrnehmung',
      questions: [
        'Kann dein Kind sicher Treppen steigen (mit Festhalten)?',
        'Kann dein Kind auf einem Bein kurz stehen?',
        'Kann dein Kind einen Ball fangen oder werfen?',
        'Kann dein Kind einfache Formen nachmalen (Kreis, Strich)?',
        'Kann dein Kind selbststaendig mit Loeffel oder Gabel essen?',
        'Springt oder huepft dein Kind von selbst (z.B. ueber Pfuetzen)?',
      ],
      tips: [
        'Baue Kletter-Moeglichkeiten in den Alltag ein (Spielplatz, Kissen)',
        'Knete, Perlen faedeln oder Sandspiel foerdern Feinmotorik',
        'Lass dein Kind barfuss laufen — das staerkt Balance und Koerpergefuehl',
      ],
    ),
    DevDomain(
      id: 'sprache',
      title: 'Sprache & Verstehen',
      emoji: '\u{1F4AC}',
      color: Color(0xFF16A34A),
      description: 'Wortschatz, Saetze bilden & Sprachverstaendnis',
      questions: [
        'Bildet dein Kind Zwei- bis Drei-Wort-Saetze?',
        'Kann dein Kind einfache Fragen beantworten (Was? Wo?)?',
        'Benennt dein Kind Alltagsgegenstaende richtig?',
        'Versteht dein Kind einfache Auftraege (Bring mir das Buch)?',
        'Singt oder summt dein Kind Lieder oder Melodien mit?',
        'Erzaehlt dein Kind von Erlebnissen (auch wenn noch nicht perfekt)?',
      ],
      tips: [
        'Sprich langsam und in kurzen Saetzen — wiederhole Woerter oft',
        'Lies jeden Tag 5-10 Minuten vor und zeige auf Bilder',
        'Benenne alles was du tust: "Ich schneide die Banane"',
      ],
    ),
    DevDomain(
      id: 'denken',
      title: 'Denken & Entdecken',
      emoji: '\u{1F4A1}',
      color: Color(0xFFF59E0B),
      description: 'Problemloesen, Neugier & Konzentration',
      questions: [
        'Kann dein Kind einfache Puzzles loesen (3-6 Teile)?',
        'Sortiert oder ordnet dein Kind Dinge nach Farbe oder Groesse?',
        'Bleibt dein Kind bei einer Aufgabe laenger als 2-3 Minuten dran?',
        'Zeigt dein Kind Interesse an Buecher-Anschauen?',
        'Versucht dein Kind Dinge herauszufinden (Was passiert wenn...)?',
        'Kann dein Kind Koerperteile benennen oder zeigen?',
      ],
      tips: [
        'Biete offene Spielmaterialien an (Bauklotze, Sand, Wasser)',
        'Stelle Warum-Fragen zurueck statt sie zu beantworten: "Was denkst DU?"',
        'Unterbrich konzentriertes Spiel nicht — auch wenn es "nur" Matschen ist',
      ],
    ),
    DevDomain(
      id: 'sozial',
      title: 'Gefuehle & Miteinander',
      emoji: '\u{1F49C}',
      color: Color(0xFFEC4899),
      description: 'Emotionen, Empathie & soziales Verhalten',
      questions: [
        'Zeigt dein Kind deutlich Freude, Wut oder Trauer?',
        'Sucht dein Kind Troest bei dir wenn es traurig oder verletzt ist?',
        'Kann dein Kind kurze Wartezeiten aushalten (mit Begleitung)?',
        'Spielt dein Kind neben oder mit anderen Kindern?',
        'Zeigt dein Kind Mitgefuehl wenn jemand weint oder sich wehgetan hat?',
        'Akzeptiert dein Kind einfache Grenzen (auch wenn es protestiert)?',
      ],
      tips: [
        'Benenne Gefuehle laut: "Du bist wuetend weil..." — das lehrt Emotionswortschatz',
        'Bleib ruhig bei Wutanfaellen — deine Ruhe ist das Modell fuer Regulation',
        'Parallelspiel (nebeneinander) ist fuer 2-3-Jaehrige voellig normal und wertvoll',
      ],
    ),
    DevDomain(
      id: 'selbst',
      title: 'Eigenstaendigkeit & Alltag',
      emoji: '\u{1F31F}',
      color: Color(0xFF8B5CF6),
      description: 'Selbststaendigkeit, Routinen & Alltagskompetenz',
      questions: [
        'Zieht sich dein Kind teilweise selbst an (Schuhe, Muetze, Jacke)?',
        'Kann dein Kind sich die Haende selbst waschen?',
        'Hilft dein Kind bei einfachen Aufgaben (Tisch decken, aufraeumen)?',
        'Zeigt dein Kind den Wunsch Dinge "alleine" zu machen?',
        'Kennt dein Kind einfache Tagesablaeufe (erst essen, dann spielen)?',
        'Kann dein Kind seinen Namen sagen wenn jemand fragt?',
      ],
      tips: [
        'Gib Wahlmoeglichkeiten statt Anweisungen: "Rote oder blaue Jacke?"',
        'Lass Fehler zu — verschuettete Milch ist ein Lernmoment, keine Katastrophe',
        'Rituale geben Sicherheit: gleicher Ablauf morgens und abends',
      ],
    ),
  ];
}

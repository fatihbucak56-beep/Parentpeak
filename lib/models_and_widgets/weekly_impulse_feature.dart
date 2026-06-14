import 'package:flutter/material.dart';

// ==========================================
// 1. DART DATEN-MODELLE
// ==========================================

/// Die paedagogischen Saeulen von Parentpeak
enum PedagogicalCategory {
  gfk, // Gewaltfreie Kommunikation
  inclusion, // Inklusion & Neurodiversitaet
  parentLeadership, // Elterliche Fuehrung
  milestones, // Allgemeine Entwicklungsschritte
}

/// Modell fuer den woechentlichen KI-Impuls
class WeeklyImpulse {
  final String id;
  final String title;
  final String contentBody;
  final String practicalTip;
  final String? audioScript;
  final PedagogicalCategory category;
  final DateTime publishDate;

  WeeklyImpulse({
    required this.id,
    required this.title,
    required this.contentBody,
    required this.practicalTip,
    this.audioScript,
    required this.category,
    required this.publishDate,
  });

  /// Mapping von JSON zu Dart-Objekt
  factory WeeklyImpulse.fromJson(Map json) {
    return WeeklyImpulse(
      id: json['id'] as String,
      title: json['title'] as String,
      contentBody: json['content_body'] as String,
      practicalTip: json['practical_tip'] as String,
      audioScript: json['audio_script'] as String?,
      category: PedagogicalCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => PedagogicalCategory.milestones,
      ),
      publishDate: DateTime.parse(json['publish_date'] as String),
    );
  }
}

// ==========================================
// 2. REUSABLE UI WIDGETS
// ==========================================

/// Eine schicke, moderne Karte zur Anzeige des KI-Impulses im Tab
class WeeklyImpulseCard extends StatelessWidget {
  final WeeklyImpulse impulse;
  final VoidCallback? onAudioPressed;

  const WeeklyImpulseCard({
    super.key,
    required this.impulse,
    this.onAudioPressed,
  });

  /// Liefert die passende Markenfarbe je nach paedagogischem Schwerpunkt
  Color _getCategoryColor(PedagogicalCategory category) {
    switch (category) {
      case PedagogicalCategory.gfk:
        return const Color(0xFF4CAF50); // Warmes Herz-Gruen fuer GfK
      case PedagogicalCategory.inclusion:
        return const Color(0xFF3F51B5); // Indigo fuer Vielfalt & Inklusion
      case PedagogicalCategory.parentLeadership:
        return const Color(0xFFFF9800); // Klares Orange fuer elterliche Fuehrung
      default:
        return const Color(0xFF009688); // Teal fuer allgemeine Meilensteine
    }
  }

  /// Uebersetzt das Enum in lesbaren Text fuer die Eltern
  String _getCategoryName(PedagogicalCategory category) {
    switch (category) {
      case PedagogicalCategory.gfk:
        return 'Gewaltfreie Kommunikation';
      case PedagogicalCategory.inclusion:
        return 'Inklusion & Vielfalt';
      case PedagogicalCategory.parentLeadership:
        return 'Elterliche Fuehrung';
      default:
        return 'Entwicklungsschritt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getCategoryColor(impulse.category);

    return Card(
      elevation: 4,
      shadowColor: themeColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header-Zeile: Badge + Audio-Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _getCategoryName(impulse.category),
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (impulse.audioScript != null)
                    IconButton(
                      icon: Icon(Icons.volume_up_rounded, color: themeColor, size: 28),
                      onPressed: onAudioPressed,
                      tooltip: 'Audio-Impuls anhoeren',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Titel des Artikels
              Text(
                impulse.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              // Haupttext (Lese-Inhalt)
              Text(
                impulse.contentBody,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Praktische Tipp-Box (Visuell hervorgehoben)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: themeColor, width: 5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: themeColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Dein Alltags-Impuls',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      impulse.practicalTip,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

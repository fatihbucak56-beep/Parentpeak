# Impulse & Entwicklung – Testfälle

---

## TC_IMP_001_LOAD_SUCCESS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_IMP_001_LOAD_SUCCESS                          |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass der wöchentliche pädagogische Impuls beim Öffnen korrekt geladen wird und das Entwicklungsschema passend zum hinterlegten Kindesalter gerendert wird.

### Voraussetzungen (Preconditions)
- User ist eingeloggt mit aktivem Trial/Premium
- Backend liefert Weekly-Impulse-Schema (Endpunkt `/api/weekly-impulse`)
- Kindesalter im Profil hinterlegt (z. B. 3 Jahre)
- Internetverbindung vorhanden

### Test-Schritte (Steps)
1. Dashboard → Kachel "Impulse & Entwicklung" antippen
2. Warten bis der Screen vollständig geladen ist
3. Prüfen: Hero-Headline wird angezeigt
4. Prüfen: Companion-Impulse (Sofort-Impuls, Verstehen, Praxis, Reflexion, Artikel) sind gelistet
5. Prüfen: Community-Posts werden geladen
6. Audio-Impuls starten (Play-Button)

### Erwartetes Ergebnis (Expected Result)
- Screen lädt innerhalb von 3 Sekunden
- Hero-Headline: Dynamischer Text basierend auf aktuellem Wochenthema
- 5 Companion-Impulse mit jeweiligem Dauer-Label (z. B. "2 Min", "4 Min")
- Community-Posts: Mindestens Seed-Posts mit Autor, Rolle, Like-Count
- Audio-Impuls: TTS oder Audio-Datei spielt ab ohne Fehler
- Diskussions-Prompt ("Frage der Woche") wird angezeigt
- Kein Overflow, kein Rendering-Fehler

---

## TC_IMP_002_OFFLINE_CACHING

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_IMP_002_OFFLINE_CACHING                       |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert, dass die App bei fehlender Internetverbindung nicht abstürzt, sondern den zuletzt gecachten Impuls anzeigt.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Impuls wurde mindestens einmal erfolgreich online geladen (Cache vorhanden)
- Gerät im Flugmodus

### Test-Schritte (Steps)
1. Impuls-Screen einmal mit Internet öffnen und schließen (Cache aufbauen)
2. Flugmodus aktivieren
3. Impuls-Screen erneut öffnen
4. Prüfen ob Inhalte angezeigt werden
5. Community-Posts-Bereich prüfen

### Erwartetes Ergebnis (Expected Result)
- App stürzt NICHT ab
- Letzter gecachter Impuls wird angezeigt (Hero, Companion-Impulse, Content)
- Dezenter Hinweis: "Offline-Modus – Inhalte sind möglicherweise nicht aktuell"
- Community-Posts: Gecachte Version oder leerer Zustand mit Hinweis
- Audio-Impuls: Funktioniert wenn TTS lokal, ansonsten deaktiviert mit Hinweis
- Like/Kommentar-Aktionen: Werden blockiert mit Offline-Hinweis

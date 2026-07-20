# GemeinsamSatt – Testfälle

---

## TC_SAT_001_SHARE_MEAL

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_SAT_001_SHARE_MEAL                            |
| **Typ**            | Positiv                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert das Erstellen einer lokalen Essens-Sharing-Aktion.

### Voraussetzungen (Preconditions)
- User ist eingeloggt mit Trial/Premium
- Standortberechtigung erteilt
- Backend erreichbar

### Test-Schritte (Steps)
1. Dashboard → "GemeinsamSatt" antippen
2. "Neue Aktion erstellen" antippen
3. Formular ausfüllen:
   - Titel: "Selbstgemachte Suppe für Nachbarn"
   - Beschreibung: "Kürbissuppe, 4 Portionen übrig"
   - Abholzeitraum: Heute, 18:00 - 20:00
4. "Veröffentlichen" antippen

### Erwartetes Ergebnis (Expected Result)
- Aktion wird im Backend gespeichert
- Koordinaten werden automatisch gesetzt
- Aktion erscheint auf der lokalen Karte
- Andere User im Umkreis sehen die Aktion
- Timer zeigt verfügbaren Zeitraum an
- Bestätigungsmeldung: "Aktion veröffentlicht!"

---

## TC_SAT_002_NO_LOCAL_MEALS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_SAT_002_NO_LOCAL_MEALS                        |
| **Typ**            | Negativ                                         |
| **Priorität**      | Medium                                          |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert das Verhalten wenn keine lokalen Essens-Aktionen verfügbar sind.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Keine aktiven Essens-Aktionen im Umkreis
- Backend liefert leere Liste

### Test-Schritte (Steps)
1. "GemeinsamSatt" öffnen
2. Karte/Liste prüfen
3. Prüfen ob Fallback-Inhalte angezeigt werden

### Erwartetes Ergebnis (Expected Result)
- Kein leerer/toter Screen
- UI schaltet nahtlos in den Digital-Modus um:
  - Globale Rezept-Tauschbörse wird angezeigt
  - KI-Rezeptvorschläge (Gemini) basierend auf Familiengröße
  - Einkaufslisten-Integration (Button: "Zutaten zur Liste")
- Hinweis: "Aktuell keine Aktionen in deiner Nähe"
- CTA: "Starte selbst eine Aktion für deine Nachbarschaft"

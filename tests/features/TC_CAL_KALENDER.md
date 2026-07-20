# Kalender – Testfälle

---

## TC_CAL_001_ADD_EVENT

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_CAL_001_ADD_EVENT                             |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass ein neuer Familientermin erfolgreich eingetragen, lokal gespeichert und mit dem Backend synchronisiert wird.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Kalender-Feature ist freigeschaltet (Trial/Premium)
- Internetverbindung vorhanden
- Push-Benachrichtigungen erlaubt

### Test-Schritte (Steps)
1. Dashboard → Kachel "Kalender" antippen
2. FAB (Floating Action Button) oder "+" antippen
3. Formular ausfüllen:
   - Titel: "Kinderarzt U7"
   - Datum: Übermorgen, 10:00 Uhr
   - End-Datum: Übermorgen, 11:00 Uhr
   - Kategorie: "Gesundheit"
4. "Speichern" antippen
5. Kalenderansicht prüfen

### Erwartetes Ergebnis (Expected Result)
- Termin erscheint im Kalender am korrekten Datum
- Termin ist lokal in SharedPreferences/SQLite gespeichert (Offline-fähig)
- Backend-Sync: POST an `/calendar/events` erfolgreich (Status 201)
- Push-Benachrichtigung: Erinnerung wird für konfigurierte Vorlaufzeit gesetzt
- Termin synchronisiert auf Geräte anderer Familienmitglieder (bei geteiltem Family-ID)
- Farb-Kodierung nach Kategorie korrekt

---

## TC_CAL_002_VALIDATION_ERROR

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_CAL_002_VALIDATION_ERROR                      |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass ein End-Datum vor dem Start-Datum vom System erkannt und blockiert wird.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Kalender-Formular ist geöffnet

### Test-Schritte (Steps)
1. Neuen Termin erstellen
2. Start-Datum: 25.07.2026, 14:00
3. End-Datum: 25.07.2026, 12:00 (VOR Start)
4. "Speichern" antippen

### Erwartetes Ergebnis (Expected Result)
- Speichern wird BLOCKIERT
- Rote Inline-Fehlermeldung unter dem End-Datum-Feld: "Das Enddatum muss nach dem Startdatum liegen."
- Kein API-Call an Backend
- Kein lokaler Speichervorgang
- Formular bleibt offen, Daten bleiben erhalten zur Korrektur
- Button "Speichern" bleibt aktiv nach Korrektur

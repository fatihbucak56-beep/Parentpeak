# Finanzen & Budget – Testfälle

---

## TC_FIN_001_SPLIT_EXPENSE

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_FIN_001_SPLIT_EXPENSE                         |
| **Typ**            | Positiv                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert die korrekte Aufteilung einer Ausgabe zwischen Partnern.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Finanzen-Feature freigeschaltet
- Mindestens 2 Familienmitglieder konfiguriert

### Test-Schritte (Steps)
1. Dashboard → "Finanzen & Budget" antippen
2. "Neue Ausgabe" antippen
3. Formular ausfüllen:
   - Betrag: 50,00 €
   - Kategorie: "Kinderkleidung"
   - Beschreibung: "Winterjacke"
   - Aufteilung: 50/50 (2 Personen)
4. "Speichern" antippen
5. Dashboard-Bilanz prüfen

### Erwartetes Ergebnis (Expected Result)
- Berechnung: 50,00 € / 2 = 25,00 € pro Person
- Person A (Zahler): +25,00 € Guthaben
- Person B (Schuldner): -25,00 € Saldo
- Gesamtbilanz im Dashboard aktualisiert
- Eintrag in der Transaktionshistorie sichtbar
- Kategorie-Zuordnung korrekt
- Backend-Sync: Speicherung in FinanceStorageService

---

## TC_FIN_002_INVALID_INPUT

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_FIN_002_INVALID_INPUT                         |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert die Eingabevalidierung bei ungültigen Beträgen und mathematischen Fehlern.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Finanzen-Formular ist geöffnet

### Test-Schritte (Steps)
1. **Buchstaben:** Betragsfeld: "fünfzig" eingeben → Speichern
2. **Sonderzeichen:** Betragsfeld: "50€$%" eingeben → Speichern
3. **Division durch Null:** Betrag: 50 €, Personenanzahl: 0 → Speichern
4. **Negativer Betrag:** Betragsfeld: "-50" eingeben → Speichern
5. **Extrem hoher Betrag:** "9999999999" eingeben → Speichern

### Erwartetes Ergebnis (Expected Result)
- **Buchstaben:** Betragsfeld erlaubt nur Ziffern + Komma/Punkt
  - Regex-Validierung: `^[0-9]+([,.][0-9]{0,2})?$`
  - Fehlermeldung: "Bitte einen gültigen Betrag eingeben"
- **Sonderzeichen:** Werden beim Tippen blockiert (inputFormatter)
  - Nur numerische Tastatur wird angeboten
- **Division durch Null:** Mathematischer Fehler wird abgefangen
  - Fehlermeldung: "Mindestens 1 Person angeben"
  - Kein Crash, kein Infinity-Wert in der Berechnung
- **Negativer Betrag:** Wird blockiert oder als Rückzahlung markiert
- **Extrem hoher Betrag:** Optional: Warnung "Betrag ungewöhnlich hoch"
- In keinem Fall: App-Crash oder unbehandelte Exception

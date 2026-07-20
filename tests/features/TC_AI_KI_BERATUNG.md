# KI Elternberatung – Testfälle

---

## TC_AI_001_PROMPT_RESPONSE

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AI_001_PROMPT_RESPONSE                        |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert, dass die Gemini-KI auf eine komplexe Erziehungsfrage innerhalb weniger Sekunden mit einer pädagogisch fundierten Antwort (GfK-Methode) antwortet.

### Voraussetzungen (Preconditions)
- User ist eingeloggt mit Trial/Premium
- `GEMINI_API_KEY` korrekt konfiguriert
- Gemini-Modell: `gemini-2.0-flash`
- Internetverbindung vorhanden
- System-Prompt: `parentAssistantSystemPrompt` (GfK-Pädagogik) aktiv

### Test-Schritte (Steps)
1. Dashboard → "KI Elternberatung" antippen
2. Chat-Screen öffnet sich
3. Nachricht eingeben: "Mein Kind (3 Jahre) hat extreme Trotzanfälle im Supermarkt. Was kann ich tun?"
4. "Senden" antippen
5. Warten auf Antwort

### Erwartetes Ergebnis (Expected Result)
- Streaming-Antwort beginnt innerhalb von 2-5 Sekunden
- Antwort ist pädagogisch fundiert:
  - Referenziert gewaltfreie Kommunikation (GfK)
  - Konkrete, alltagsnahe Tipps
  - Einfühlsamer Ton (nicht belehrend)
  - Keine medizinischen Diagnosen
- Antwort hat mindestens 3-5 Sätze (nicht zu kurz)
- Chat-History wird korrekt dargestellt (User-Bubble + KI-Bubble)
- Kein Markdown-Rendering-Fehler
- Kein Timeout, kein API-Error

---

## TC_AI_002_EMPTY_OR_SPAM_INPUT

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AI_002_EMPTY_OR_SPAM_INPUT                    |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass leere Nachrichten und Spam-Eingaben (Rate-Limiting) korrekt abgefangen werden.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- KI-Chat ist geöffnet

### Test-Schritte (Steps)
1. **Leere Nachricht:** Textfeld leer lassen → "Senden" antippen
2. **Nur Leerzeichen:** "   " eingeben → "Senden" antippen
3. **Rate-Limiting:** 10x schnell hintereinander "Test" senden (innerhalb 5 Sekunden)

### Erwartetes Ergebnis (Expected Result)
- **Leere Nachricht:**
  - Senden-Button ist deaktiviert (grau) wenn Textfeld leer ist ODER
  - Hinweis: "Bitte gib eine Frage ein."
  - Kein API-Call wird gesendet
- **Nur Leerzeichen:**
  - Wird wie leere Nachricht behandelt (trim)
  - Kein API-Call
- **Rate-Limiting:**
  - Nach 3-5 schnellen Nachrichten: lokale Sperre greift
  - Hinweis: "Bitte kurz warten bevor du die nächste Nachricht sendest."
  - Gemini API-Fehler `429 Too Many Requests` wird abgefangen
  - Kein Crash, kein unbehandelter Error
  - Nach Wartezeit (10-30 Sek): Senden wieder möglich

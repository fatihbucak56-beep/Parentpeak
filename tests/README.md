# Parentpeak – QA Test Repository

## Übersicht

Dieses Verzeichnis enthält alle manuellen und automatisierbaren Testfälle für die Parentpeak-App.
Die Struktur folgt einem standardisierten QA-Framework für Mobile-Apps.

## Verzeichnisstruktur

```
tests/
├── README.md                   ← Du bist hier
├── auth/                       ← Authentifizierung, Session, DSGVO
│   ├── TC_AUTH_LOGIN.md
│   ├── TC_AUTH_LOGOUT.md
│   └── TC_AUTH_DELETE_ACCOUNT.md
├── features/                   ← Funktionale Testfälle pro Feature-Kachel
│   ├── TC_IMP_IMPULSE.md
│   ├── TC_CAL_KALENDER.md
│   ├── TC_EVE_EVENTS.md
│   ├── TC_MAR_VERSCHENKMARKT.md
│   ├── TC_MAT_ELTERN_MATCH.md
│   ├── TC_AI_KI_BERATUNG.md
│   ├── TC_ORG_ORGANISATION.md
│   ├── TC_SAT_GEMEINSAMSATT.md
│   └── TC_FIN_FINANZEN.md
├── security/                   ← Penetration- und Injection-Tests
├── performance/                ← Ladezeiten, Stress-Tests, Memory-Profiling
└── e2e/                        ← End-to-End Flows (Multi-Screen Journeys)
```

## Testfall-Schema

Jeder Testfall folgt exakt diesem Format:

```markdown
## TC_[MODUL]_[NR]_[NAME]

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_MODUL_NR_NAME                                |
| **Typ**            | Positiv / Negativ / Security / Performance      |
| **Priorität**      | Critical / High / Medium / Low                  |
| **Automatisierbar**| Ja / Nein / Teilweise                           |

### Beschreibung
Kurze Erklärung was dieser Testfall prüft.

### Voraussetzungen (Preconditions)
- Zustand der App vor Testbeginn
- Benötigte Testdaten
- Konfigurationsanforderungen

### Test-Schritte (Steps)
1. Schritt-für-Schritt Anleitung
2. Exakt reproduzierbar
3. Keine Annahmen

### Erwartetes Ergebnis (Expected Result)
- Konkretes, messbares Ergebnis
- UI-Zustand nach Abschluss
- Datenbank-/Backend-Zustand
```

## Prioritäten

| Stufe      | Bedeutung                                              |
|------------|-------------------------------------------------------|
| Critical   | App-Crash, Datenverlust, Sicherheitslücke             |
| High       | Feature unbenutzbar, schlechte UX für Kernfunktion    |
| Medium     | Feature eingeschränkt, Workaround möglich             |
| Low        | Kosmetisch, Edge-Case, selten reproduzierbar          |

## Namenskonvention

- `TC` = Test Case
- Modul-Prefix: `AUTH`, `IMP`, `CAL`, `EVE`, `MAR`, `MAT`, `AI`, `ORG`, `SAT`, `FIN`
- Fortlaufende Nummer: `001`, `002`, ...
- Suffix: Kurzbeschreibung in UPPER_SNAKE_CASE

## Ausführung

- **Manuell:** Testfälle werden auf echten Geräten (iOS + Android) und Simulatoren durchgeführt
- **Automatisiert:** Integration Tests via `flutter test` und `integration_test/`
- **CI/CD:** GitHub Actions Workflow `.github/workflows/flutter-analyze.yml`

## Verantwortung

| Rolle          | Zuständig für                          |
|----------------|----------------------------------------|
| QA Engineer    | Testfall-Erstellung, Ausführung        |
| Dev Team       | Fix-Implementierung, Unit Tests        |
| Product Owner  | Priorisierung, Abnahme                 |

---

Letzte Aktualisierung: Juli 2026

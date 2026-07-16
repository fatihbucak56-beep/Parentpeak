# Parentpeak 14-Tage Sprintplan (Stressarm + Robust)

Stand: 2026-07-15
Owner: Product + Mobile
Ziel: Weniger elterlicher Stress bei gleichzeitig hoeherer Zuverlaessigkeit in den Kernflows.

## Zielmetriken

- Kurzcheck-Abschlussrate: +15%
- Abbruchrate im Entwicklungsbereich: -20%
- Wiederkehr in 7 Tagen: +10%
- Fehlerquote bei Wochenimpuls-Laden: -30%

## Prinzipien

- Keine Pflicht-Rhetorik in Erinnerungen.
- Jeder Fehlerzustand hat einen ruhigen Ausweichpfad.
- Nutzerinnen und Nutzer sollen auch bei Teil-Ausfall weiterarbeiten koennen.

## Tage 1-3: Stabilitaet Kernflow

1. Wochenimpuls-Fehlerzustand harmonisieren
- Scope: freundliche Fehlermeldungen fuer Timeout/Offline/Backend, Retry plus Ausweichpfad Entwicklung.
- Status: umgesetzt in Entwicklung-Tab.
- Akzeptanz: kein leerer Screen ohne Handlungsoption.

2. Nicht-blockierende Teilfehler
- Scope: Sekundaerdaten (Community/Verifizierung) duerfen Primar-Flow nicht blockieren.
- Status: umgesetzt in Entwicklung-Tab.
- Akzeptanz: Wochenimpuls bleibt sichtbar, Info-Hinweis bei Teil-Ausfall.

3. Pull-to-Refresh Standard
- Scope: manuelles Neuladen in Kernlisten/Kernkarten.
- Status: umgesetzt fuer Wochenimpuls.
- Akzeptanz: RefreshIndicator aktiv und funktional.

## Tage 4-6: Stressfreie Reminder

1. Reminder-Frequency-Cap
- Scope: max. 1 aktiver Reminder-Hinweis pro 24h fuer Entwicklung.
- Akzeptanz: kein Reminder-Spam bei mehrfacher App-Nutzung.

2. Ruhemodus-Shortcuts
- Scope: 3 Tage, 7 Tage, 14 Tage direkt waehlbar.
- Akzeptanz: mit 1 Tap pausierbar, spaeter leicht reaktivierbar.

3. Tonalitaet-Review
- Scope: alle Reminder-/Nudge-Texte in beruhigende Sprache ueberfuehren.
- Akzeptanz: keine Pflicht-/Druck-Formulierungen.

## Tage 7-9: Vertrauen und Erklaerbarkeit

1. Ergebnis-Erklaerung vereinfachen
- Scope: Score/Legend in Klartext (Was bedeutet das jetzt im Alltag?).
- Akzeptanz: 3 kurze, konkrete Next Steps ohne Fachjargon.

2. Sicherheits- und Grenzen-Hinweise
- Scope: sensible Module mit klaren Hinweisen zu Datenschutz und medizinischen Grenzen.
- Akzeptanz: Hinweise sind sichtbar, kurz, nicht angstmachend.

3. Empty/Offline-Fallback fuer Home-CTA
- Scope: Wenn Ziel nicht ladbar, direkt alternatives Ziel anbieten.
- Akzeptanz: jeder CTA fuehrt zu nutzbarer Alternative.

## Tage 10-12: Accessibility und Performance

1. Dynamische Schriftgroessen pruefen
- Scope: Home, Entwicklung, Profil mit grossen Text-Skalierungen.
- Akzeptanz: kein abgeschnittener Kerntext, keine unbedienbaren Buttons.

2. Kontrast-Check
- Scope: zentrale Cards, CTA, Hinweisleisten.
- Akzeptanz: WCAG-nahe Lesbarkeit in Light-Theme.

3. First-View Performance
- Scope: schwere Inhalte spaet laden, Above-the-fold priorisieren.
- Akzeptanz: erste Interaktion subjektiv schneller.

## Tage 13-14: Messung und Release-Entscheidung

1. KPI-Dashboard lokal
- Scope: Home-CTA-Taps, Kurzcheck-Completion, Retry-Haeufigkeit.
- Akzeptanz: taegliche Werte auslesbar.

2. Vorher/Nachher Review
- Scope: iOS Vergleichs-Screens aktualisieren und in Review-Deck einpflegen.
- Akzeptanz: klare visuelle Delta-Dokumentation.

3. Go/No-Go Check
- Scope: Produkt, Design, Tech gemeinsam.
- Akzeptanz: Baseline freigegeben oder konkrete Restpunkte mit Termin.

## Ticket-Backlog (umsetzbar)

- PP-UX-201: Reminder Frequency Cap (24h)
- PP-UX-202: Pause-Shortcuts 3/7/14 Tage
- PP-UX-203: Reminder Copy Softening
- PP-UX-204: Score Klartext Next Steps
- PP-UX-205: Trust Notice Harmonisierung
- PP-UX-206: Home CTA Fallback Routing
- PP-A11Y-207: Dynamic Type Kernscreens
- PP-A11Y-208: Contrast Fix Pass
- PP-PERF-209: Above-the-fold Priorisierung
- PP-METR-210: Retry und Completion KPI Erweiterung

## Definition of Done

- Kein Kernscreen ohne klaren Fehler-/Fallback-Zustand.
- Reminder wirken motivierend, nicht verpflichtend.
- Messdaten zeigen Verbesserung in Completion und Retention.
- Vergleichsdeck ist aktualisiert und intern freigegeben.

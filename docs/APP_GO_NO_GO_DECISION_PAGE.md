# App Go/No-Go Decision Page

## Zweck

Diese Seite ist fuer das finale Release-Meeting. Ziel ist eine klare Entscheidung ohne offene Interpretationen.

## Meeting Setup

- Dauer: 30 Minuten
- Teilnehmer: Product, Tech Lead, Mobile, Backend, Support
- Entscheidungsowner: Product + Tech Lead

## Inputs (vor Meeting fertig)

1. [APP_RELEASE_PRIORITY_BOARD.md](APP_RELEASE_PRIORITY_BOARD.md)
2. [APP_GO_LIVE_OPERATIONS_CHECKLIST.md](APP_GO_LIVE_OPERATIONS_CHECKLIST.md)
3. [POST_LAUNCH_7_DAY_MONITORING_PLAN.md](POST_LAUNCH_7_DAY_MONITORING_PLAN.md)
4. Letzter Live-Smoke Lauf (Log/Output)

## Hard Gates (muessen alle true sein)

- [ ] Live Smoke fuer den geplanten Scope ist vollstaendig gruen
- [ ] Kritische Security/Datenschutz-Checks sind bestanden
- [ ] Zahlungsfluss in Zielmodus verifiziert (inkl. Fehlerpfade)
- [ ] Monitoring und Alerts sind aktiv und getestet
- [ ] Support-Kanal + Runbook sind bereit
- [ ] Rollout-Stop-Regeln sind dokumentiert und verstanden

Wenn ein Hard Gate false ist: automatisch NO-GO.

## Risk Check (0-2 pro Punkt)

0 = kein Risiko, 1 = kontrollierbar, 2 = kritisch

- Stabilitaet (Crash/API)
- Payments
- Datenschutz/Sicherheit
- Support-Bereitschaft
- Rollback-Faehigkeit

Gesamtwertung:

- 0-3: GO
- 4-6: GO mit Auflagen
- >= 7: NO-GO

## Entscheidungsprotokoll

- Datum/Uhrzeit:
- App Version/Build:
- Rollout-Plan (z. B. 10% -> 25% -> 50% -> 100%):
- Entscheidung: GO / GO mit Auflagen / NO-GO
- Auflagen:
- Verantwortliche Person fuer Go-Live:
- Naechster Review-Zeitpunkt (T+2h / T+24h):

## Falls GO mit Auflagen

1. Auflagen als konkrete Tasks mit Owner + ETA dokumentieren.
2. Nur erste Rollout-Stufe freigeben.
3. Naechste Stufe erst nach Erfuellung aller Auflagen.

## Falls NO-GO

1. Blocker-Liste priorisieren (Top 3 zuerst).
2. Fix-ETA mit Owner festlegen.
3. Neues Go/No-Go Meeting terminieren.

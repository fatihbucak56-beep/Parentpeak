# App Go-Live Operations Checklist

## Ziel

Operative Freigabe in klaren Schritten mit Ownern und Checkpunkten.

## T-7 bis T-3 Tage

| Check | Aufgabe | Owner | Status |
|---|---|---|---|
| Ops-1 | Monitoring Dashboards und Alerts pruefen | Backend | [ ] |
| Ops-2 | Crashlytics inkl. Symbol Upload pruefen | Mobile | [ ] |
| Ops-3 | Stripe Live Webhook Sicherheit pruefen | Backend | [ ] |
| Ops-4 | Datenschutz-Flow (Delete/Export) verifizieren | Backend | [ ] |
| Ops-5 | Finales Store Listing (Texte/Visuals) freigeben | Product | [ ] |

## T-2 bis T-1 Tage

| Check | Aufgabe | Owner | Status |
|---|---|---|---|
| Ops-6 | Finalen Release Smoke gegen Live ausfuehren | Tech Lead | [ ] |
| Ops-7 | Rollout-Plan (10% -> 25% -> 50% -> 100%) festlegen | Product | [ ] |
| Ops-8 | Stop-Regeln und Incident-Owner verbindlich dokumentieren | Tech Lead | [ ] |
| Ops-9 | Support-Runbook und Antwortmakros finalisieren | Support | [ ] |
| Ops-10 | Go/No-Go Meeting mit Entscheidung protokollieren | Product | [ ] |

## Release-Tag (T0)

| Uhrzeit | Aufgabe | Owner | Status |
|---|---|---|---|
| T0 | Release ausrollen (staged) | Product | [ ] |
| T0 + 15m | Health + kritische APIs + Payment Probe | Backend | [ ] |
| T0 + 30m | Crash/ANR/Kernfluss in App pruefen | Mobile | [ ] |
| T0 + 60m | Support-Kanal aktiv pruefen | Support | [ ] |
| T0 + 120m | Entscheidung: naechste Rollout-Stufe ja/nein | Product + Tech Lead | [ ] |

## T+24h

| Check | Aufgabe | Owner | Status |
|---|---|---|---|
| Day1-1 | Error Budget Review (API 5xx, Crash-Free) | Tech Lead | [ ] |
| Day1-2 | Top Support-Themen priorisieren | Product | [ ] |
| Day1-3 | Hotfix-Entscheidung falls noetig | Backend + Mobile | [ ] |

## Stop-Regeln (harte Kriterien)

1. Crash-Free Session Rate < 99.0% fuer 30 Minuten.
2. API 5xx > 2% fuer 15 Minuten auf Kernendpunkten.
3. Zahlungsfehlerquote > 5% ohne externen Provider-Ausfall.
4. Kritischer Datenschutz- oder Sicherheitsbefund.

Wenn eine Stop-Regel triggert:

1. Rollout sofort pausieren.
2. Incident-Channel oeffnen.
3. Ursache isolieren, Fix-Plan mit ETA kommunizieren.
4. Erst nach verifiziertem Smoke erneut fortsetzen.

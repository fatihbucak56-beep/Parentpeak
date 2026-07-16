# App Release Priority Board (Must-Have vs. Post-Launch)

## Ziel

Dieses Board trennt strikt zwischen "vor Release zwingend" und "direkt nach Release". Fokus: Risiko senken, Vertrauen steigern, Conversion sichern.

## Must-Have vor Release (Blocker)

| ID | Thema | Aufgabe | Owner | Deadline | Erfolgskriterium |
|---|---|---|---|---|---|
| M1 | Stabilitaet | Finalen Live Smoke (Security + Weekly Community) als Nachweis dokumentieren | Tech Lead | T-2 Tage | 100% OK in Smoke-Protokoll |
| M2 | Monitoring | Alerts fuer 5xx, Crash Spike, Zahlungsfehler aktivieren | Backend + Mobile | T-2 Tage | Alerts testweise ausgeloest und empfangen |
| M3 | Payment Safety | Stripe success/fail/refund + doppelte Webhooks verifizieren | Backend | T-2 Tage | Keine inkonsistenten Zahlungszustaende |
| M4 | Datenschutz | Data Delete + Data Export End-to-End mit Testkonto | Backend + Product | T-2 Tage | Beide Flows erfolgreich und nachvollziehbar |
| M5 | Onboarding | First Value < 60 Sekunden, unnötige Friktion entfernen | Mobile + Product | T-1 Tag | Interner Test: 8/10 schaffen Kernaktion < 60s |
| M6 | Store Readiness | Store Text, Screenshots, Privacy/AGB/Support konsistent | Product + Marketing | T-1 Tag | Vollstaendige Assets + Texte freigegeben |
| M7 | Rollout Guardrails | Stop-Regeln fuer gestaffelten Rollout festlegen | Product + Tech Lead | T-1 Tag | Dokumentierte Go/No-Go Regeln vorhanden |

## Direkt nach Release (P1)

| ID | Thema | Aufgabe | Owner | Zielzeitraum | Erfolgskriterium |
|---|---|---|---|---|---|
| P1 | UX-Qualitaet | Top 5 Nutzer-Friktionen aus Feedback beheben | Product + Mobile | Woche 1 | 5 konkrete UX-Fixes live |
| P2 | Performance | Startup/Ladezeiten messen und optimieren | Mobile | Woche 1 | p95 Startup sinkt messbar |
| P3 | Support Ops | FAQ + Makro-Antworten fuer Top 10 Support-Faelle | Support + Product | Woche 1 | Reaktionszeit < 24h |
| P4 | Vertrauen | In-App Transparenztexte zu Daten + Moderation nachschaerfen | Product | Woche 1 | Rueckfragen zu Datenschutz sinken |
| P5 | Activation | Onboarding Varianten mit kleinem A/B Test evaluieren | Product + Data | Woche 2 | Aktivierungsrate steigt >= 10% relativ |

## Nach Release (P2)

| ID | Thema | Aufgabe | Owner | Zielzeitraum | Erfolgskriterium |
|---|---|---|---|---|---|
| P6 | Growth | Referral/Einladungs-Loop optimieren | Product | Woche 3-4 | Invite Conversion verbessert |
| P7 | Community | Moderation-Workflows automatisieren (Triaging) | Backend | Woche 3-4 | Weniger manuelle Moderationszeit |
| P8 | Retention | Erinnerungslogik mit Nutzenfokus feinjustieren | Product + Mobile | Woche 3-4 | D7 Retention steigt |

## Priorisierungsregel

1. Alles mit Betriebsrisiko oder Rechtsrisiko ist immer Must-Have.
2. Alles mit reinem Komfortgewinn ist nie Release-Blocker.
3. Bei Konflikten gewinnt Stabilitaet vor Feature-Umfang.

# Release Decision Protocol (Solo Founder)

Datum: 2026-07-14
Produkt: Parentpeak
Entscheider: Solo Founder (du)

## Entscheidung

- Entscheidung: **GO mit Auflagen**
- Rollout-Modus: **staged rollout**
- Zielsystem: `https://parentpeak.onrender.com`

## Technischer Nachweis (bereits erfolgt)

Vollstaendiger Live-Smoke gegen Produktion war gruen fuer:

1. Backend Security Smoke
2. Stripe Webhook Smoke
3. Parent Matching Smoke
4. Weekly Impulse Community Smoke

## Auflagen vor 100% Rollout

1. Store-Listing final pruefen (Titel, Untertitel, Screenshots, Privacy, Support-Kontakt)
2. Real-Device Smoke auf mindestens 1 iOS + 1 Android (echtes Netz)
3. Alert-Empfang testen (mind. ein Test-Alarm sichtbar)
4. Support-Baseline setzen (Antwortzeit-Ziel und Standardantworten)

## Rollout-Plan (Solo)

1. Stufe 1: 10%
2. Stufe 2: 25%
3. Stufe 3: 50%
4. Stufe 4: 100%

Regel: Naechste Stufe nur, wenn keine Stop-Regel ausgeloest wurde.

## Stop-Regeln (hart)

1. Crash-Free Sessions < 99.0% fuer 30 Minuten
2. API 5xx > 2% fuer 15 Minuten auf Kernendpunkten
3. Payment Success < 90%
4. Kritischer Sicherheits- oder Datenschutzvorfall

## Incident-Ablauf (Solo)

1. Rollout sofort pausieren
2. Ursache isolieren (Logs + letzte Aenderung)
3. Hotfix priorisieren und deployen
4. Re-Smoke ausfuehren
5. Erst dann Rollout fortsetzen

## Solo-Operations-Plan

### T+2h

1. Health, Error-Rate, Crash-Signal, Payment-Signal pruefen
2. Erste Support-Nachrichten clustern
3. Entscheidung: bei 10% bleiben oder auf 25% erhoehen

### T+24h

1. KPI-Check: Crash-Free, API 5xx, Payment Success, Activation
2. Top 3 Friktionen dokumentieren
3. Entscheidung: 25% -> 50% oder halten

### T+72h

1. Stabilitaetstrend pruefen
2. Top UX-Fixes fuer Woche 1 priorisieren
3. Entscheidung: 50% -> 100% oder halten

## Solo-KPI-Ziele (Woche 1)

1. Crash-Free Sessions >= 99.5%
2. API 5xx < 0.5%
3. Payment Success >= 95%
4. First Core Action < 60s bei >= 70% der neuen Nutzer
5. Erstantwortzeit Support < 12h

## Abschlussvermerk

- Dieser Beschluss gilt fuer den aktuell getesteten Scope.
- Bei jeder neuen kritischen Aenderung: erneuter Full Smoke vor weiterer Rollout-Stufe.

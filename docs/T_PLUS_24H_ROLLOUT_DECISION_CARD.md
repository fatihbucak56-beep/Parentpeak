# T+24h Rollout Decision Card

## Zweck

Diese Karte ist deine 2-Minuten-Entscheidung fuer die Rollout-Stufe von 10% auf 25%.

## Harte Stop-Regeln (sofort STOP)

1. Crash-Free Sessions < 99.0%
2. API 5xx auf Kernendpunkten > 2.0%
3. Payment Success < 90%
4. Kritischer Security- oder Datenschutzvorfall offen

Wenn eine Regel true ist: Rollout pausieren und zuerst fixen.

## 5 Ja/Nein Fragen fuer GO von 10% auf 25%

1. Crash-Free Sessions >= 99.5%?
2. API 5xx auf Kernendpunkten < 0.5%?
3. Payment Success >= 95%?
4. Keine offenen Sev-1/Sev-2 Incidents?
5. Support-Erstantwortzeit < 12h?

## Entscheidungslogik

- 5x Ja: GO auf 25%
- 4x Ja: HOLD bei 10%, in 12h neu pruefen
- <=3x Ja: STOP, Hotfix priorisieren

## Kurzprotokoll

- Datum/Uhrzeit:
- Aktuelle Stufe:
- Antworten (1-5):
- Entscheidung: GO / HOLD / STOP
- Naechster Check:
- Notizen:

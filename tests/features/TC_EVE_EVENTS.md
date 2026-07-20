# Events & Aktivitäten – Testfälle

---

## TC_EVE_001_STRIPE_PAYMENT_SUCCESS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_EVE_001_STRIPE_PAYMENT_SUCCESS                |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Teilweise (Stripe Testmodus)                    |

### Beschreibung
Verifiziert, dass ein kostenpflichtiges Event erfolgreich über Stripe bezahlt und die Buchung bestätigt wird.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Event existiert mit `costPerPerson > 0` (z. B. 15,00 EUR)
- Stripe Publishable Key konfiguriert (`pk_test_...`)
- Backend: `STRIPE_SECRET_KEY` gesetzt
- Testmodus aktiv (Stripe Test-Kreditkarte: `4242 4242 4242 4242`)

### Test-Schritte (Steps)
1. Dashboard → "Events & Aktivitäten" antippen
2. Kostenpflichtiges Event auswählen (z. B. "Eltern-Yoga-Kurs – 15 €")
3. "Teilnehmen & Bezahlen" antippen
4. Stripe PaymentSheet öffnet sich
5. Test-Kreditkarte eingeben: `4242 4242 4242 4242`, Exp: 12/30, CVC: 123
6. "Bezahlen" bestätigen

### Erwartetes Ergebnis (Expected Result)
- Stripe PaymentSheet öffnet sich korrekt (kein Crash)
- Zahlung wird verarbeitet (Ladeindikator)
- Backend: POST `/payments/stripe/initiate` → PaymentIntent erstellt
- Stripe Webhook: `payment_intent.succeeded` wird empfangen
- Backend: `PaymentTransaction` mit Status `completed` in DB gespeichert
- App: Buchungsbestätigung wird angezeigt ("Buchung erfolgreich!")
- Event-Teilnahme: `EventParticipation` Status → `accepted`
- User sieht sich in der Teilnehmerliste des Events

---

## TC_EVE_002_STRIPE_PAYMENT_FAILED

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_EVE_002_STRIPE_PAYMENT_FAILED                 |
| **Typ**            | Negativ                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Ja (Stripe Test-Decline-Card)                   |

### Beschreibung
Verifiziert, dass eine fehlgeschlagene Zahlung sauber abgefangen wird ohne Platzreservierung.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Kostenpflichtiges Event verfügbar
- Stripe Testmodus aktiv
- Stripe Test-Decline-Card: `4000 0000 0000 0002`

### Test-Schritte (Steps)
1. Kostenpflichtiges Event auswählen
2. "Teilnehmen & Bezahlen" antippen
3. Stripe PaymentSheet: Decline-Card eingeben (`4000 0000 0000 0002`)
4. "Bezahlen" bestätigen
5. Auf Fehlerreaktion warten

### Erwartetes Ergebnis (Expected Result)
- Stripe gibt Fehlercode zurück (`card_declined`)
- App fängt Fehler sauber ab
- Fehlermeldung: "Zahlung fehlgeschlagen – Bitte Zahlungsmethode prüfen."
- Kein Kursplatz wird reserviert (kein `EventParticipation` Record)
- Kein `PaymentTransaction` mit Status `completed`
- User kann erneut versuchen mit anderer Karte
- Kein App-Crash, kein unbehandelte Exception

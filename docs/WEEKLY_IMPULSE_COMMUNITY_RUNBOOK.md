# Weekly Impulse Community Runbook

## Ziel

Dieses Runbook beschreibt den Betriebsablauf fuer den Wochenimpuls-Communitybereich mit:

- Community-Posts
- Likes und Kommentaren
- Moderationsmeldungen
- globalem Ausblenden/Wiederfreigeben
- Fachverifizierung fuer paedagogische Stimmen

## Erforderliche Backend-Umgebungsvariablen

```bash
BACKEND_API_TOKEN=...
REQUIRE_AUTH_FOR_WRITES=1
INTERNAL_MODERATOR_EMAILS=lead@parentpeak.de,ops@parentpeak.de
INTERNAL_MODERATOR_DOMAINS=parentpeak.de,parentpeak.com
```

Hinweise:

- `INTERNAL_MODERATOR_EMAILS` ist fuer einzelne bekannte Reviewer gedacht.
- `INTERNAL_MODERATOR_DOMAINS` erlaubt interne Moderation fuer komplette Firmen-/Team-Domains.
- Moderations- und Verifizierungs-Review-Endpunkte akzeptieren nur interne E-Mails.

## Relevante Endpunkte

### Community lesen und schreiben

- `GET /api/weekly-impulse`
- `POST /api/weekly-impulse/community/posts`
- `POST /api/weekly-impulse/community/posts/:postId/like`
- `POST /api/weekly-impulse/community/posts/:postId/comments`
- `POST /api/weekly-impulse/community/posts/:postId/report`

### Moderation

- `GET /api/weekly-impulse/community/reports`
- `POST /api/weekly-impulse/community/reports/:reportId/resolve`
- `POST /api/weekly-impulse/community/posts/:postId/moderation-visibility`

### Fachverifizierung

- `GET /api/weekly-impulse/community/verification-status`
- `POST /api/weekly-impulse/community/verification-requests`
- `GET /api/weekly-impulse/community/verification-requests`
- `POST /api/weekly-impulse/community/verification-requests/:requestId/approve`

## Erwartetes Verhalten

### Normaler Nutzer

- darf Community-Beitraege lesen, posten, liken, kommentieren und melden
- darf keine Moderationslisten laden
- darf keine Moderationsentscheidungen treffen
- darf keine Verifizierungsanfragen anderer pruefen oder freigeben

### Interner Moderator

- darf Moderationsreports laden
- darf Reports als bearbeitet markieren
- darf Beitraege global ausblenden oder wieder freigeben
- darf offene Fachverifizierungsanfragen sehen und freigeben

## Go-Live Checkliste

1. Backend mit den neuen Env-Variablen deployen.
2. Mit internem Account pruefen, dass das Admin-/Moderationspanel in der App funktioniert.
3. Mit normalem Account pruefen, dass Moderations-Review-Endpunkte serverseitig `403` liefern.
4. Test-Community-Post erstellen.
5. Test-Report auf den Post absetzen.
6. Mit internem Account den Post im Moderationspanel laden.
7. Testweise global ausblenden und wieder freigeben.
8. Testweise eine Fachverifizierungsanfrage stellen.
9. Mit internem Account die Anfrage freigeben.
10. Danach einen neuen Paedagogik-Post erstellen und pruefen, dass das Verifizierungs-Badge automatisch gesetzt wird.

## Empfohlene Smoke-Tests

### Voller Community-Smoke als Script

```bash
BACKEND_BASE_URL=https://YOUR_BACKEND \
INTERNAL_REVIEWER_EMAIL=lead@parentpeak.de \
INTERNAL_REVIEWER_NAME="Lead Review" \
bash scripts/weekly_impulse_community_smoke_test.sh
```

Optional im bestehenden Sammel-Smoke:

```bash
BACKEND_BASE_URL=https://YOUR_BACKEND \
RUN_BACKEND_SECURITY_SMOKE=1 \
RUN_STRIPE_WEBHOOK_SMOKE=0 \
RUN_WEEKLY_IMPULSE_COMMUNITY_SMOKE=1 \
INTERNAL_REVIEWER_EMAIL=lead@parentpeak.de \
bash scripts/release_smoke_suite.sh
```

### Moderationszugriff intern

Erwartung: `200`

```bash
curl -i "https://YOUR_BACKEND/api/weekly-impulse/community/reports?impulseId=imp_years_3_gfk_w1&includeResolved=1&moderatorEmail=lead@parentpeak.de"
```

### Moderationszugriff extern blockiert

Erwartung: `403`

```bash
curl -i "https://YOUR_BACKEND/api/weekly-impulse/community/reports?impulseId=imp_years_3_gfk_w1&includeResolved=1&moderatorEmail=someone@gmail.com"
```

### Fachanfrage intern freigeben

Erwartung: `200`

```bash
curl -i -X POST "https://YOUR_BACKEND/api/weekly-impulse/community/verification-requests/REQUEST_ID/approve" \
  -H "Content-Type: application/json" \
  -d '{
    "reviewerName": "Lead Review",
    "reviewerEmail": "lead@parentpeak.de",
    "reviewNote": "Ausbildung geprueft.",
    "verificationLabel": "Verifizierte Fachstimme"
  }'
```

## Produkt-Hinweis

Die UI blendet Moderations- und Review-Funktionen bereits sinnvoll ein oder aus. Die eigentliche Sicherheit kommt jetzt aber aus dem Backend. Das ist der entscheidende Unterschied zwischen Demo-Verhalten und belastbarem Produktverhalten.

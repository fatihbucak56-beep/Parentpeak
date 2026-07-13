# Kettenbrecher API Contract (v1)

Dieses Dokument definiert den verbindlichen Backend-Vertrag fuer die Phase-3-Funktionen:
- SOS responder-action
- Multiweek hub sync
- AI Tarnmapping JSON

## 1) SOS Responder Action

### Endpoint
- `POST /kettenbrecher/sos/responder-action`

### Request Schema
```json
{
  "sosId": "string (required)",
  "responderUserId": "string (required)",
  "status": "pending|accepted|enRoute|resolved (required)",
  "etaMinutes": "integer >= 0 (optional)",
  "updatedAt": "ISO-8601 datetime (required)",
  "schemaVersion": "v1 (optional, recommended)"
}
```

### Response Schema
```json
{
  "success": true,
  "data": {
    "item": {
      "sosId": "string",
      "responderUserId": "string",
      "status": "pending|accepted|enRoute|resolved",
      "etaMinutes": "integer|null",
      "updatedAt": "ISO-8601 datetime"
    }
  },
  "meta": {
    "schemaVersion": "v1"
  }
}
```

### Validation Rules
- `sosId` darf nicht leer sein.
- `responderUserId` darf nicht leer sein.
- `status` muss einer der 4 erlaubten Werte sein.
- `etaMinutes` ist optional, aber nur gueltig wenn `status` in `accepted|enRoute`.
- `updatedAt` darf nicht in ungueltigem Datumsformat sein.

### Error Codes
- `400`: ungultige Felder
- `404`: SOS oder Responder existiert nicht
- `409`: Statuskonflikt (z. B. bereits abgeschlossen)

## 2) Multiweek Hub Sync

### Endpoint
- `GET /kettenbrecher/hub`
- `POST /kettenbrecher/hub`

### Hub Payload Schema
```json
{
  "id": "string (required)",
  "hubName": "string (required)",
  "memberUserIds": ["string", "..."],
  "weeklyRotationalPlanner": {
    "YYYY-MM-DD": "userId"
  },
  "weeklyRotationHistoryByWeekStart": {
    "YYYY-MM-DD": {
      "YYYY-MM-DD": "userId"
    }
  },
  "fairnessCookCountByUserId": {
    "userId": "integer >= 0"
  },
  "childAllergiesByUserId": {
    "userId": ["string", "..."]
  },
  "childPreferencesByUserId": {
    "userId": ["string", "..."]
  },
  "schemaVersion": "v1 (optional, recommended)"
}
```

### Validation Rules
- `memberUserIds` muss mindestens 2 Eintraege enthalten.
- Alle UserIds in Plan/History/Fairness muessen in `memberUserIds` existieren.
- Datumskeys muessen `YYYY-MM-DD` sein.
- `weeklyRotationalPlanner` sollte 7 Tage fuer die aktuelle Woche enthalten.
- `fairnessCookCountByUserId` darf keine negativen Werte enthalten.

### Conflict Rules
- `POST` mit veralteter Revision sollte `409` liefern (optimistic locking empfohlen).
- Serverseitig kann optional `revision` oder `etag` genutzt werden.

## 3) AI Tarnmapping JSON

### Endpoint
- `POST /kettenbrecher/ai/tarn-mapping`

### Request Schema
```json
{
  "recipe": {
    "id": "string",
    "title": "string",
    "ingredients": [
      { "name": "string", "amount": "string" }
    ]
  },
  "parentPrompt": "string (required)",
  "candidateIngredients": ["zucchini", "linsen", "spinat"],
  "schemaVersion": "v1"
}
```

### Response Schema
```json
{
  "success": true,
  "data": {
    "aiTarnMapping": [
      {
        "ingredientKey": "string",
        "hiddenIngredient": "string",
        "camouflageMethod": "string",
        "textureHint": "string",
        "colorHint": "string"
      }
    ]
  },
  "meta": {
    "model": "string",
    "schemaVersion": "v1"
  }
}
```

### Validation Rules
- Maximal 5 Tarnschritte.
- `ingredientKey` muss in `candidateIngredients` enthalten sein.
- Keine leeren Strings in den 4 Textfeldern.
- Antwort darf kein Markdown enthalten, nur reines JSON.

## Security & Privacy
- Keine exakten Adressen in SOS-Payloads speichern.
- Geokoordinaten nur mit zweckgebundener Nutzung und minimalem Retention-Zeitraum.
- Alle Endpunkte mit Auth + Familien-/Hub-Berechtigung absichern.
- PII in Logs maskieren.

## Versioning
- `schemaVersion: v1` auf Request/Response mitfuehren.
- Breaking changes nur mit neuem Versionspfad oder Version-Header.

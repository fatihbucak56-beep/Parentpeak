# Next Gen Food Feed API Contract (v1)

Dieses Dokument beschreibt die produktive Backend-Struktur fuer:
- Vertical Video Feed (`CommunitySnack`)
- Audio-Hacks (`AudioHack`)
- Zutaten-Retter Sharing (`IngredientShare`)

## 1) Community Snacks

### GET /community/snacks?page={page}&pageSize={pageSize}

Response:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "snack-123",
        "title": "Brokkoli unsichtbar in 15 Sekunden",
        "videoUrl": "https://cdn.example.com/snacks/123.mp4",
        "linkedRecipeId": "recipe-brokkoli-pasta",
        "authorId": "anna",
        "viewsCount": 1230,
        "likesCount": 91,
        "locationCoordinates": {
          "latitude": 52.5211,
          "longitude": 13.4061
        }
      }
    ]
  },
  "meta": {
    "page": 1,
    "pageSize": 5,
    "hasMore": true,
    "nextPage": 2,
    "schemaVersion": "v1"
  }
}
```

### POST /community/snacks

Request:
```json
{
  "id": "snack-123",
  "title": "Brokkoli unsichtbar in 15 Sekunden",
  "videoUrl": "https://cdn.example.com/snacks/123.mp4",
  "linkedRecipeId": "recipe-brokkoli-pasta",
  "authorId": "anna",
  "viewsCount": 0,
  "likesCount": 0,
  "locationCoordinates": {
    "latitude": 52.5211,
    "longitude": 13.4061
  },
  "familyId": "demo-family-001",
  "schemaVersion": "v1"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "item": {
      "id": "snack-123",
      "title": "Brokkoli unsichtbar in 15 Sekunden",
      "videoUrl": "https://cdn.example.com/snacks/123.mp4",
      "linkedRecipeId": "recipe-brokkoli-pasta",
      "authorId": "anna",
      "viewsCount": 0,
      "likesCount": 0,
      "locationCoordinates": {
        "latitude": 52.5211,
        "longitude": 13.4061
      }
    }
  },
  "meta": {
    "schemaVersion": "v1"
  }
}
```

Validation:
- `title`, `videoUrl`, `linkedRecipeId`, `authorId` sind Pflichtfelder.
- `videoUrl` muss HTTPS sein.
- `viewsCount`, `likesCount` >= 0.

## 2) Audio Hacks

### GET /community/audio-hacks

Response:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "hack-1",
        "recipeId": "recipe-brokkoli-pasta",
        "userId": "leonie",
        "audioUrl": "https://cdn.example.com/audio/hack-1.m4a",
        "durationSeconds": 14,
        "upvotes": 42,
        "transcript": "Nimm doppelt Frischkaese, dann wird es cremiger."
      }
    ]
  },
  "meta": {
    "schemaVersion": "v1"
  }
}
```

### POST /community/audio-hacks

Request:
```json
{
  "id": "hack-1",
  "recipeId": "recipe-brokkoli-pasta",
  "userId": "leonie",
  "audioUrl": "https://cdn.example.com/audio/hack-1.m4a",
  "durationSeconds": 14,
  "upvotes": 0,
  "transcript": "Nimm doppelt Frischkaese, dann wird es cremiger.",
  "familyId": "demo-family-001",
  "schemaVersion": "v1"
}
```

Validation:
- `recipeId`, `userId`, `audioUrl` sind Pflichtfelder.
- `durationSeconds` > 0.
- `upvotes` >= 0.

## 3) Ingredient Shares

### GET /community/ingredient-shares

Response:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "share-1",
        "userId": "anna",
        "ingredientName": "Mandelmus",
        "status": "available",
        "geoHash": "u33dc1",
        "location": {
          "latitude": 52.5207,
          "longitude": 13.4060
        },
        "note": "Fast neu, nur 2 EL genutzt."
      }
    ]
  },
  "meta": {
    "schemaVersion": "v1"
  }
}
```

### POST /community/ingredient-shares

Request:
```json
{
  "id": "share-1",
  "userId": "anna",
  "ingredientName": "Mandelmus",
  "status": "available",
  "geoHash": "u33dc1",
  "location": {
    "latitude": 52.5207,
    "longitude": 13.4060
  },
  "note": "Fast neu, nur 2 EL genutzt.",
  "familyId": "demo-family-001",
  "schemaVersion": "v1"
}
```

Validation:
- `status` nur `available|reserved`.
- `ingredientName` darf nicht leer sein.
- `location.latitude` und `location.longitude` muessen gueltig sein.

## Error Handling
- `400`: Request Validation Error
- `401/403`: Auth/Berechtigung fehlt
- `404`: Ressource nicht gefunden
- `409`: Konflikt (z. B. status bereits reserviert)
- `500`: Interner Serverfehler

## Envelope-Kompatibilitaet
Der Client akzeptiert sowohl:
- `data.items`
- `items` direkt auf Root-Ebene
- `data.item` fuer POST-Antworten

Damit bleiben auch bestehende Wrapper-Varianten kompatibel.

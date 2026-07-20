# Verschenkmarkt – Testfälle

---

## TC_MAR_001_UPLOAD_ITEM

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_MAR_001_UPLOAD_ITEM                           |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert, dass ein Artikel mit Foto, Titel und Beschreibung erfolgreich eingestellt wird und für andere User im Umkreis sichtbar ist.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Standortberechtigung erteilt
- Kamera/Fotomediathek-Berechtigung erteilt
- Backend erreichbar
- Firebase Storage konfiguriert (FIREBASE_STORAGE_BUCKET)

### Test-Schritte (Steps)
1. Dashboard → "Verschenkmarkt" antippen
2. "Artikel einstellen" / Upload-Button antippen
3. Formular ausfüllen:
   - Titel: "Winterjacke Größe 104"
   - Beschreibung: "Kaum getragen, sehr guter Zustand"
   - Kategorie: "Kleidung"
   - Zustand: "Gut"
   - Foto: Aus Galerie auswählen oder Kamera
4. "Einstellen" antippen

### Erwartetes Ergebnis (Expected Result)
- Foto wird zu Firebase Storage hochgeladen (`POST /uploads/image`)
- Artikel wird in PostgreSQL gespeichert (Prisma: `TreasureItem.create`)
- Felder korrekt: Titel, Beschreibung, Kategorie, Zustand, photoUrl
- GPS-Koordinaten werden automatisch aus Standort gesetzt
- Visibility: `nearby` (Standard: 10 km Radius)
- Status: `available`
- Artikel ist in der Kartenansicht für andere User im Umkreis sichtbar
- Bestätigungsmeldung: "Artikel erfolgreich eingestellt!"

---

## TC_MAR_002_LOCATION_DENIED

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_MAR_002_LOCATION_DENIED                       |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert das Verhalten wenn der User die GPS-Standortberechtigung verweigert hat.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- GPS-Standortberechtigung in Systemeinstellungen ENTZOGEN
- App hat keinen Zugriff auf `CoreLocation` (iOS) / `LocationManager` (Android)

### Test-Schritte (Steps)
1. Standortberechtigung in Geräteeinstellungen für Parentpeak deaktivieren
2. "Verschenkmarkt" öffnen
3. "Artikel einstellen" antippen
4. Formular ausfüllen (Titel, Foto etc.)
5. "Einstellen" antippen

### Erwartetes Ergebnis (Expected Result)
- App stürzt NICHT ab
- Vor dem Einstellen: Hinweis-Dialog erscheint:
  - "Standort wird benötigt, um deinen Artikel in der Nähe anzuzeigen."
  - Option 1: "Standort freischalten" → Öffnet System-Einstellungen
  - Option 2: "Manuell eingeben" → Textfeld für PLZ oder Stadt
- Wenn manuell eingegeben: Artikel wird mit Stadt-Zentrum-Koordinaten gespeichert
- Wenn verweigert: Einstellen wird blockiert mit klarer Begründung
- Kein latitude/longitude = null in Datenbank ohne Fallback

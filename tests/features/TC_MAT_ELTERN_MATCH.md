# Eltern Match – Testfälle

---

## TC_MAT_001_MATCH_SUCCESS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_MAT_001_MATCH_SUCCESS                         |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Teilweise (benötigt 2 Accounts)                 |

### Beschreibung
Verifiziert, dass ein gegenseitiges "Verbinden" zweier Elternteile im selben Radius zu einem erfolgreichen Match und Chat-Initialisierung führt.

### Voraussetzungen (Preconditions)
- 2 registrierte User (User A + User B)
- Beide haben Matching-Profil erstellt (Name, Stadt, Interessen, Kindesalter)
- Beide im selben Radius (z. B. beide in "Berlin", < 20 km)
- Backend erreichbar

### Test-Schritte (Steps)
1. **User A:** Eltern Match öffnen → Profil von User B wird angezeigt
2. **User A:** "Verbinden" antippen
3. **User B:** Eltern Match öffnen → Profil von User A wird angezeigt
4. **User B:** "Verbinden" antippen
5. Match-Bestätigung prüfen

### Erwartetes Ergebnis (Expected Result)
- Backend: `recordAction` für User A → action: `like`, matchedProfileId: B
- Backend: `recordAction` für User B → action: `like`, matchedProfileId: A
- Gegenseitiges Like erkannt → Match erstellt
- User B sieht Match-Bestätigung (BottomSheet "Neue bestätigte Verbindung")
- Privater Chatraum wird initialisiert
- Match erscheint in `_matchedProfiles` beider User
- Chat-Button (Bubble-Icon) neben dem Match ist tippbar
- Match-Score wird korrekt angezeigt (Kompatibilitäts-%)

---

## TC_MAT_002_RADIUS_FALLBACK

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_MAT_002_RADIUS_FALLBACK                       |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert das Verhalten wenn keine Eltern-Profile im eingestellten Radius verfügbar sind.

### Voraussetzungen (Preconditions)
- User ist eingeloggt mit Matching-Profil
- Radius auf 10 km eingestellt
- Keine anderen Profile im 10-km-Umkreis registriert
- Backend liefert leere Match-Liste

### Test-Schritte (Steps)
1. Eltern Match öffnen
2. Filter-Einstellungen: Radius 10 km
3. Prüfen ob Profile angezeigt werden
4. Wenn leer: Prüfen wie die App reagiert

### Erwartetes Ergebnis (Expected Result)
- Kein leerer/toter Screen
- `_EmptyMatchState` Widget wird angezeigt mit:
  - Freundliche Illustration oder Icon
  - Text: "Noch keine Eltern in deiner Nähe gefunden"
  - Vorschlag: "Versuche den Radius zu erweitern"
  - Button: "Radius erweitern" → setzt auf 50 km und refresht
- Automatische Radius-Erweiterung (optional): 10 → 50 → 100 → landesweit
- Bei absolutem Leerstand: Hinweis auf Community-Einladung
  - "Lade andere Eltern ein – je mehr mitmachen, desto bessere Matches!"
  - Share-Button für Einladungslink
- Button "Filter zurücksetzen" setzt alle Filter + Radius auf Default

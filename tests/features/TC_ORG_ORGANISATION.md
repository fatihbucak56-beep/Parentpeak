# Organisation – Testfälle

---

## TC_ORG_001_LIST_SYNC

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_ORG_001_LIST_SYNC                             |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Teilweise (benötigt 2 Geräte)                   |

### Beschreibung
Verifiziert, dass ein neues Item auf der geteilten Einkaufsliste in Echtzeit auf dem Gerät des Partners erscheint.

### Voraussetzungen (Preconditions)
- 2 User im selben Family-Circle (gleiche `familyId`)
- Beide Geräte online
- Backend erreichbar (Shopping-Endpunkt `/shopping`)

### Test-Schritte (Steps)
1. **Gerät A:** Organisation → Einkaufsliste öffnen
2. **Gerät A:** Neues Item hinzufügen: "Hafermilch"
3. **Gerät A:** "Hinzufügen" bestätigen
4. **Gerät B:** Einkaufsliste öffnen (oder bereits geöffnet)
5. Prüfen ob "Hafermilch" auf Gerät B erscheint

### Erwartetes Ergebnis (Expected Result)
- Item wird sofort lokal auf Gerät A angezeigt (Optimistic UI)
- Backend: POST an `/shopping` → Status 201
- Gerät B: Item "Hafermilch" erscheint innerhalb von 2-5 Sekunden
- Sync-Mechanismus: Polling oder Push-Notification-Trigger
- Item hat korrekten Timestamp und Creator-Info
- Reihenfolge der Liste ist konsistent auf beiden Geräten
- Checkbox-Status (erledigt/offen) wird synchronisiert

---

## TC_ORG_002_OFFLINE_CONCURRENCY

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_ORG_002_OFFLINE_CONCURRENCY                   |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Nein (manueller Multi-Device-Test)              |

### Beschreibung
Verifiziert die Konfliktauflösung wenn zwei Familienmitglieder offline denselben Listeneintrag bearbeiten.

### Voraussetzungen (Preconditions)
- 2 User im selben Family-Circle
- Beide Geräte im Flugmodus
- Einkaufsliste enthält Item "Milch" (vorhanden auf beiden Geräten lokal gecacht)

### Test-Schritte (Steps)
1. Beide Geräte in Flugmodus versetzen
2. **Gerät A:** Item "Milch" umbenennen zu "Hafermilch 1L"
3. **Gerät B:** Item "Milch" als erledigt markieren
4. **Gerät A:** Flugmodus deaktivieren → Sync startet
5. **Gerät B:** Flugmodus deaktivieren → Sync startet
6. Beide Listen nach 30 Sekunden prüfen

### Erwartetes Ergebnis (Expected Result)
- Kein App-Crash auf beiden Geräten
- Kein Datenverlust: "Milch" ist nicht verschwunden
- Konfliktauflösung (Last-Write-Wins oder Merge):
  - **Variante A (Last-Write-Wins):** Der zuletzt synchronisierte Zustand gewinnt
  - **Variante B (Merge):** Umbenennung UND Erledigt-Status werden zusammengeführt
- Keine doppelten Einträge entstehen
- Beide Geräte zeigen nach 60 Sekunden denselben konsistenten Zustand
- Optional: Hinweis "Ein Konflikt wurde automatisch aufgelöst" im Sync-Log

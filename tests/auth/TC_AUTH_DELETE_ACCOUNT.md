# Konto löschen – Testfälle

---

## TC_AUTH_006_DELETE_ACCOUNT_SUCCESS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_006_DELETE_ACCOUNT_SUCCESS                |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Teilweise (Backend-Verification manuell)        |

### Beschreibung
Verifiziert die vollständige DSGVO-konforme Löschung eines Benutzerkontos inklusive aller personenbezogenen Daten, Familienprofile und aktiver Abonnements.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Konto hat aktive Daten: Familienprofile, Kalendereinträge, Chat-Nachrichten
- Optional: Aktives Stripe-Abo vorhanden
- Internetverbindung stabil

### Test-Schritte (Steps)
1. Profil → Familienprofil → Kontoaktionen
2. "Konto löschen" antippen
3. Bestätigungs-Dialog erscheint mit Warnung:
   - "Konto wirklich löschen? Diese Aktion ist endgültig."
   - Auflistung was gelöscht wird
4. "Endgültig löschen" antippen
5. Warten auf Bestätigung

### Erwartetes Ergebnis (Expected Result)
- **Lokale Daten:**
  - `SharedPreferences.clear()` → alle lokalen Caches gelöscht
  - `flutter_secure_storage` → Session-Token gelöscht
  - `AuthService.instance.logout()` → Firebase signOut
- **Backend/Datenbank (DSGVO Art. 17):**
  - User-Record in PostgreSQL: GELÖSCHT (nicht nur deaktiviert)
  - Alle Familien-Mitgliedschaften: ENTFERNT
  - Alle EventParticipations: CASCADE DELETE
  - Alle Messages/ChatReports: CASCADE DELETE
  - Alle TreasureItems: CASCADE DELETE
  - Alle PaymentTransactions: GELÖSCHT
  - ParentMatchingProfile: GELÖSCHT
  - Hochgeladene Fotos in Firebase Storage: GELÖSCHT
- **Stripe:**
  - Aktives Abo wird storniert (`stripe.subscriptions.cancel`)
  - Zahlungsmethoden werden entfernt
- **Firebase Auth:**
  - `user.delete()` → Firebase-Konto permanent gelöscht
- **Navigation:**
  - Weiterleitung zu Login-Screen via `DemoApp` → `AuthGate`
- **Post-Deletion:**
  - Erneuter Login-Versuch mit gleicher E-Mail: "Kein Konto gefunden"

---

## TC_AUTH_007_DELETE_ACCOUNT_CANCEL

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_007_DELETE_ACCOUNT_CANCEL                 |
| **Typ**            | Positiv (Abbruch)                               |
| **Priorität**      | High                                            |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass der Abbruch des Löschprozesses absolut keine Datenveränderung auslöst.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Konto hat aktive Daten

### Test-Schritte (Steps)
1. Profil → Familienprofil → Kontoaktionen
2. "Konto löschen" antippen
3. Bestätigungs-Dialog erscheint
4. "Abbrechen" antippen
5. Weiter in der App navigieren (Dashboard, Kalender etc.)

### Erwartetes Ergebnis (Expected Result)
- Dialog schließt sich sofort
- Konto bleibt vollständig aktiv
- Keine API-Calls an Backend (kein `/account/delete-data` Request)
- Keine lokalen Daten gelöscht
- Session-Token intakt
- Alle Features weiterhin nutzbar
- Keine Fehlermeldungen

---

## TC_AUTH_008_DELETE_ACCOUNT_OFFLINE

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_008_DELETE_ACCOUNT_OFFLINE                |
| **Typ**            | Negativ                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert, dass die Kontolöschung im Offline-Modus blockiert wird, da eine unvollständige Löschung (lokal gelöscht, Backend nicht) zu Dateninkonsistenz führen würde.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Flugmodus aktivieren NACH dem Öffnen des Profil-Screens

### Test-Schritte (Steps)
1. Gerät in Flugmodus versetzen
2. Profil → Familienprofil → Kontoaktionen
3. "Konto löschen" antippen
4. Bestätigungs-Dialog → "Endgültig löschen" antippen
5. Auf Systemreaktion warten

### Erwartetes Ergebnis (Expected Result)
- Löschvorgang wird NICHT lokal ausgeführt
- Fehlermeldung erscheint: "Für die Kontolöschung wird eine stabile Internetverbindung benötigt. Bitte versuche es erneut wenn du online bist."
- Konto bleibt vollständig aktiv
- Kein Session-Token gelöscht
- Kein lokaler `SharedPreferences.clear()`
- User kann Vorgang nach Internetwiederherstellung erneut starten

---

## TC_AUTH_012_DELETE_ACCOUNT_FIREBASE_ERROR

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_012_DELETE_ACCOUNT_FIREBASE_ERROR         |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Nein (simulierter Firebase-Fehler)              |

### Beschreibung
Verifiziert das Verhalten wenn Firebase `user.delete()` fehlschlägt (z. B. Token abgelaufen, requires-recent-login).

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Firebase-Session ist älter als 5 Minuten (requires-recent-login Szenario)

### Test-Schritte (Steps)
1. Login durchführen, 10+ Minuten warten
2. Kontolöschung starten
3. Firebase wirft `requires-recent-login`

### Erwartetes Ergebnis (Expected Result)
- App fängt Firebase-Exception ab
- SnackBar-Fehlermeldung: "Fehler beim Löschen des Kontos: [Fehlerdetail]"
- Konto bleibt aktiv
- Kein partieller Löschzustand (Atomarität)
- User wird ggf. aufgefordert sich erneut anzumelden bevor Löschung möglich ist

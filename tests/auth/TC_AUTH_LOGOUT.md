# Logout – Testfälle

---

## TC_AUTH_004_LOGOUT_SUCCESS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_004_LOGOUT_SUCCESS                       |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass ein eingeloggter User sich erfolgreich abmelden kann und alle Session-Daten sicher gelöscht werden.

### Voraussetzungen (Preconditions)
- User ist eingeloggt und befindet sich im Dashboard
- Session-Token existiert in `flutter_secure_storage`
- FCM-Token ist beim Backend registriert

### Test-Schritte (Steps)
1. Bottom-Navigation: "Profil" Tab antippen
2. "Familienprofil" öffnen
3. Zum Abschnitt "Kontoaktionen" scrollen
4. Button "Abmelden" antippen
5. Bestätigungs-Dialog: "Abmelden" bestätigen

### Erwartetes Ergebnis (Expected Result)
- Bestätigungs-Dialog erscheint: "Abmelden? Ihr werdet von diesem Gerät abgemeldet."
- Nach Bestätigung:
  - `AuthService.instance.currentUser` == null
  - Session-Token in `flutter_secure_storage` gelöscht (Key: `pp_current_user`)
  - Firebase Auth: `signOut()` aufgerufen
  - FCM-Token wird beim Backend deregistriert (`/fcm/unregister`)
  - Navigation: Kompletter Widget-Tree wird durch `DemoApp` → `AuthGate` ersetzt
  - `AuthGate` erkennt `currentUser == null` → zeigt Login-Screen
- Kein Datenverlust für andere Familienmitglieder

---

## TC_AUTH_005_LOGOUT_BACK_BUTTON

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_005_LOGOUT_BACK_BUTTON                   |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert, dass nach dem Logout der Hardware-/Software-Zurück-Button keinen Zugriff auf geschützte Screens ermöglicht.

### Voraussetzungen (Preconditions)
- User hat sich gerade erfolgreich abgemeldet (TC_AUTH_004 bestanden)
- Login-Screen ist sichtbar

### Test-Schritte (Steps)
1. Logout durchführen (TC_AUTH_004 Steps 1-5)
2. Login-Screen ist sichtbar
3. Hardware-Zurück-Button drücken (Android) oder Swipe-Back-Gesture (iOS)
4. Prüfen welcher Screen angezeigt wird
5. Versuch über Deep-Link auf geschützten Screen zuzugreifen: `parentpeak://home`

### Erwartetes Ergebnis (Expected Result)
- Zurück-Button: App bleibt auf Login-Screen ODER schließt sich (Android-Standard)
- Kein Zugriff auf Dashboard, HomeScreen oder ProfilScreen möglich
- `Navigator.pushAndRemoveUntil` hat den gesamten Navigation-Stack gelöscht
- Deep-Link: Wird durch `AuthGate` abgefangen → Login-Screen
- Kein gecachter Screen wird angezeigt
- `IndexedStack` Tabs sind nicht mehr im Widget-Tree

---

## TC_AUTH_011_LOGOUT_CANCEL

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_011_LOGOUT_CANCEL                        |
| **Typ**            | Positiv (Abbruch)                               |
| **Priorität**      | Medium                                          |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass der Abbruch des Logout-Dialogs keine Seiteneffekte hat.

### Voraussetzungen (Preconditions)
- User ist eingeloggt
- Kontoaktionen-Bereich ist sichtbar

### Test-Schritte (Steps)
1. Button "Abmelden" antippen
2. Bestätigungs-Dialog erscheint
3. "Abbrechen" antippen

### Erwartetes Ergebnis (Expected Result)
- Dialog schließt sich
- User bleibt auf dem Profil-Screen
- Session-Token unverändert
- `AuthService.instance.currentUser` unverändert
- Keine API-Calls ausgelöst
- App verhält sich normal weiter

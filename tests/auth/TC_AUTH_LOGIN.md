# Login – Testfälle

---

## TC_AUTH_001_LOGIN_SUCCESS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_001_LOGIN_SUCCESS                        |
| **Typ**            | Positiv                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass ein registrierter User sich mit korrekten Anmeldedaten erfolgreich einloggen kann und zur Haupt-App weitergeleitet wird.

### Voraussetzungen (Preconditions)
- Ein gültiges Konto existiert (z. B. `test@parentpeak.de` / `Test1234!`)
- User ist abgemeldet (kein aktiver Session-Token im SecureStorage)
- Internetverbindung vorhanden
- Firebase Auth: Email/Password aktiviert

### Test-Schritte (Steps)
1. App starten → Login-Screen wird angezeigt
2. E-Mail-Feld: `test@parentpeak.de` eingeben
3. Passwort-Feld: `Test1234!` eingeben
4. Button "Anmelden" antippen
5. Warten bis Ladeindikator verschwindet

### Erwartetes Ergebnis (Expected Result)
- Login erfolgreich, kein Fehler
- Session-Token wird verschlüsselt in `flutter_secure_storage` gespeichert
- Weiterleitung zum HomeScreen (Dashboard mit 9 Kacheln)
- `AuthService.instance.currentUser` ist nicht null
- `AuthService.instance.currentUser.email` == `test@parentpeak.de`
- Bei erneutem App-Start: User bleibt eingeloggt (Persistenz)

---

## TC_AUTH_002_LOGIN_INVALID_CREDENTIALS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_002_LOGIN_INVALID_CREDENTIALS            |
| **Typ**            | Negativ                                         |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass bei falschen Anmeldedaten (falsches Passwort oder nicht existierende E-Mail) eine verständliche Fehlermeldung angezeigt wird und kein Login erfolgt.

### Voraussetzungen (Preconditions)
- User ist abgemeldet
- Internetverbindung vorhanden

### Test-Schritte (Steps)
1. App starten → Login-Screen
2. **Variante A – Falsches Passwort:**
   - E-Mail: `test@parentpeak.de` (existiert)
   - Passwort: `FalschesPasswort99!`
   - "Anmelden" antippen
3. **Variante B – Nicht existierende E-Mail:**
   - E-Mail: `gibtsnicht@xyz.com`
   - Passwort: `IrgendEtwas1!`
   - "Anmelden" antippen

### Erwartetes Ergebnis (Expected Result)
- Kein Login, User bleibt auf Login-Screen
- Rote Fehlerbox erscheint mit Text: "E-Mail oder Passwort ist nicht korrekt."
- Kein Session-Token wird gespeichert
- Passwort-Feld wird NICHT geleert (UX-Best-Practice)
- Kein Stack-Trace, kein App-Crash
- Nach 5 Fehlversuchen: Firebase rate-limiting greift → "Zu viele Versuche. Bitte später erneut versuchen."

---

## TC_AUTH_003_LOGIN_SQL_INJECTION

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_003_LOGIN_SQL_INJECTION                  |
| **Typ**            | Security                                        |
| **Priorität**      | Critical                                        |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass Injection-Angriffe über die Login-Felder abgefangen werden und das System sicher bleibt.

### Voraussetzungen (Preconditions)
- User ist abgemeldet
- App ist im Debug- oder Release-Modus

### Test-Schritte (Steps)
1. Login-Screen öffnen
2. E-Mail-Feld: `' OR 1=1 --` eingeben
3. Passwort-Feld: `'; DROP TABLE users; --` eingeben
4. "Anmelden" antippen
5. Dasselbe mit XSS-Payload: `<script>alert('xss')</script>@test.com`

### Erwartetes Ergebnis (Expected Result)
- E-Mail-Validator erkennt ungültige E-Mail-Syntax → "Bitte gib eine gültige E-Mail-Adresse ein."
- Kein Login möglich
- Kein Server-Fehler, keine Exception, kein Crash
- Firebase Auth: Parameterisierte Queries verhindern Injection von Natur aus
- Backend (Prisma): Prepared Statements schützen PostgreSQL
- Kein Datenleck, keine unautorisierten Datenbank-Operationen
- Security-Event wird NICHT in User-Facing UI exponiert (kein SQL-Fehlertext sichtbar)

---

## TC_AUTH_009_LOGIN_EMPTY_FIELDS

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_009_LOGIN_EMPTY_FIELDS                   |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Ja                                              |

### Beschreibung
Verifiziert, dass leere Eingabefelder korrekt validiert werden bevor ein Login-Request gesendet wird.

### Voraussetzungen (Preconditions)
- User ist abgemeldet
- Login-Screen ist sichtbar

### Test-Schritte (Steps)
1. Beide Felder leer lassen → "Anmelden" antippen
2. Nur E-Mail eingeben, Passwort leer → "Anmelden" antippen
3. Nur Passwort eingeben, E-Mail leer → "Anmelden" antippen

### Erwartetes Ergebnis (Expected Result)
- Schritt 1: Inline-Fehlermeldung unter E-Mail-Feld: "E-Mail ist erforderlich."
- Schritt 2: Inline-Fehlermeldung unter Passwort-Feld: "Passwort ist erforderlich."
- Schritt 3: Inline-Fehlermeldung unter E-Mail-Feld: "E-Mail ist erforderlich."
- In keinem Fall wird ein Netzwerk-Request gesendet
- Button bleibt aktiv (kein Freeze)

---

## TC_AUTH_010_LOGIN_NETWORK_ERROR

| Feld               | Inhalt                                          |
|--------------------|------------------------------------------------|
| **Test-ID**        | TC_AUTH_010_LOGIN_NETWORK_ERROR                  |
| **Typ**            | Negativ                                         |
| **Priorität**      | High                                            |
| **Automatisierbar**| Teilweise                                       |

### Beschreibung
Verifiziert das Verhalten bei Netzwerkausfall während des Login-Versuchs.

### Voraussetzungen (Preconditions)
- User ist abgemeldet
- Gerät in Flugmodus versetzen NACH dem Öffnen des Login-Screens

### Test-Schritte (Steps)
1. Login-Screen öffnen
2. Flugmodus aktivieren
3. Gültige Credentials eingeben
4. "Anmelden" antippen
5. 10 Sekunden warten

### Erwartetes Ergebnis (Expected Result)
- Ladeindikator erscheint, verschwindet nach Timeout
- Fehlermeldung: "Netzwerkfehler. Bitte Internetverbindung prüfen."
- Kein Crash, kein unendlicher Spinner
- User kann sofort erneut versuchen sobald Verbindung steht

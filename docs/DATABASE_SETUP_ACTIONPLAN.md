# 🚀 PostgreSQL + Prisma Setup - Aktionsplan

## ✅ ALREADY DONE:
- ✅ Prisma installiert (`npm install @prisma/client -D prisma`)
- ✅ Prisma initialisiert (`npx prisma init`)
- ✅ Prisma Schema erstellt mit allen Datenbankmodellen
- ✅ `.env.example` dokumentiert

## 🔥 JETZT MACHEN (Deine Aufgaben):

### SCHRITT 1: PostgreSQL Database auf Render erstellen (10 min)

**URL:** https://dashboard.render.com/new/postgres

**Schritte:**
1. Klick "New +" oben rechts
2. Wähle "PostgreSQL"
3. Konfiguration:
   - **Name:** `parentpeak-db`
   - **PostgreSQL Version:** Latest
   - **Region:** Gleiche wie Parentpeak Service (z.B. Frankfurt)
   - **Datadog APM:** Optional (deactivated)
4. Klick "Create Database"
5. **WARTEN** bis Status "Available" (ca. 5 min)

### SCHRITT 2: Database URL kopieren (2 min)

Nach Creation:
1. Gehe zu deiner neuen Database in Render
2. Oben rechts: "Connections"
3. Kopiere: **Internal Database URL** (NICHT External!)
4. Sieht so aus: `postgresql://user:password@internal-host:5432/dbname`

### SCHRITT 3: Render Environment aktualisieren (2 min)

**URL:** https://dashboard.render.com/web/srv-d8q0p5j6sc1c73auvfa0/env

1. Oben im Service-Dashboard: "Environment"
2. Klick "Add Environment Variable"
3. **Key:** `DATABASE_URL`
4. **Value:** (paste die URL von Schritt 2)
5. Klick "Save"
6. Render auto-deployed (30-60 sec)

### SCHRITT 4: Lokal testen (5 min)

```bash
cd /Users/aram/Documents/GitHub/Parentpeak/backend

# Setze DATABASE_URL in .env (für lokales Testing)
# Beispiel DATABASE_URL="postgresql://..."

# Teste Datenbankverbindung
npx prisma db push  # ⚠️ Oder npx prisma migrate dev

# Wenn erfolgreich: schema.prisma wurde in DB erstellt ✅
```

**Erwartet Dich:**
```
Environment variables loaded from .env
Prisma schema loaded from prisma/schema.prisma
PostgreSQL 15.7 on x86_64-pc-linux-gnu

Datasource "db": PostgreSQL database "parentpeak_db" at "internal-host:5432"

Creating migration history table

✓ Executed migrations

Your database is now in sync with your schema.
```

### SCHRITT 5: Erste Migration committen (2 min)

```bash
git add backend/prisma/
git add backend/.env.example
git commit -m "feat(database): add PostgreSQL schema and Prisma ORM"
git push origin main
```

---

## 📋 Checkliste zum Abhaken:

- [ ] PostgreSQL Datenbank auf Render erstellt
- [ ] DATABASE_URL kopiert
- [ ] DATABASE_URL in Render Environment hinzugefügt
- [ ] Lokales Testing erfolgreich (`npx prisma db push`)
- [ ] Changes committed & gepusht

---

## 🎯 Nächster Schritt danach:

**Backend umschreiben:**
- Ersetze: `const todos = []` → `prisma.todo.findMany()`
- Ersetze: `.push()` → `prisma.model.create()`
- Ersetze: `.filter()` → `prisma.model.findMany({ where: {...} })`

Etwa 50-80 Codezeilen zu rewrite pro Datenmodell.

---

## ⚠️ WICHTIG:

- **Nutze Internal Database URL** (nicht External) → schneller, sicherer
- `.env` mit DATABASE_URL **NICHT commiten** (nur `.env.example`)
- Migrations **IMMER committen**
- Render auto-deployed = neue Umgebungsvariablen automatisch aktiv

---

## 🆘 Wenn etwas schiefgeht:

```bash
# Datenbankverbindung testen
npx prisma db execute --stdin <<< "SELECT 1;"

# Schema in DB überprüfen
npx prisma studio  # Öffnet UI zum Datenbank-Anschauen

# Migrationen überprüfen
npx prisma migrate status
```

---

Bereit? Sag Bescheid wenn Datenbank erstellt ist! 🚀

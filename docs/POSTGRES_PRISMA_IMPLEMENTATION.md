# PostgreSQL + Prisma Implementation Plan

## 🎯 Phasen-Plan (7 Wochen zu Production-Ready)

### **Phase 1: Database Setup (Tage 1-2)**
- [ ] PostgreSQL Datenbank auf Render erstellen
- [ ] Prisma installieren + konfigurieren
- [ ] `.env.database` mit CONNECTION_URL
- [ ] Erstes Prisma Schema: `users`, `families`, `payments`
- [ ] Erste Migration: `npx prisma migrate dev --name init`

### **Phase 2: Critical Data Persistence (Tage 3-7)**
- [ ] Schema für: `events`, `event_chats`, `event_participations`
- [ ] Schema für: `payment_transactions` (Audit Log!)
- [ ] Schema für: `messages`, `providers`
- [ ] Seed Script: Alt-Daten importieren
- [ ] Backend API rewrite: Replace Arrays → DB Queries

### **Phase 3: Payment Hardening (Tage 8-14)**
- [ ] Idempotency Keys implementieren
- [ ] Payment Order Verification
- [ ] Refund Flow
- [ ] Audit Logging für ALLE Payment-Events
- [ ] Tests schreiben

### **Phase 4: Monitoring & Logging (Tage 15-21)**
- [ ] Sentry Setup
- [ ] Winston Logging
- [ ] Health Checks
- [ ] Alert System

### **Phase 5: Security & Testing (Tage 22-35)**
- [ ] Input Validation (Zod)
- [ ] Security Scanning
- [ ] Integration Tests
- [ ] Load Testing

### **Phase 6: Deployment Pipeline (Tage 36-42)**
- [ ] GitHub Actions CI/CD
- [ ] Database Migrations in CI/CD
- [ ] Backup Strategy
- [ ] Disaster Recovery Plan

### **Phase 7: Beta & Launch (Tage 43-49)**
- [ ] Beta mit 50 Test-Nutzern
- [ ] Monitoring & Fixes
- [ ] Production Launch
- [ ] Ongoing Support

---

## 📋 Heute: Schritt 1 - PostgreSQL Setup

### Schritt 1.1: Neue Datenbank auf Render erstellen

**URL:** https://dashboard.render.com/new/postgres

1. Klick "New +" → PostgreSQL
2. Name: `parentpeak-db`
3. Region: (gleiche wie Parentpeak Service)
4. PostgreSQL Version: Latest
5. "Create Database"
6. Warte bis Status "Available" (5 min)
7. Kopiere: **Internal Database URL** (nicht External!)

**Beispiel Internal URL:**
```
postgresql://user:password@internal-host:5432/dbname
```

### Schritt 1.2: Prisma Setup im Backend

```bash
cd backend

# 1. Prisma installieren
npm install @prisma/client
npm install -D prisma

# 2. Prisma initialisieren
npx prisma init

# 3. DATABASE_URL in .env setzen
# DATABASE_URL="postgresql://..."

# 4. Erstes Schema erstellen (siehe unten)

# 5. Erste Migration
npx prisma migrate dev --name init
```

### Schritt 1.3: Prisma Schema (backend/prisma/schema.prisma)

```prisma
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id                    String   @id @default(cuid())
  email                 String   @unique
  passwordHash          String
  passwordSalt          String
  firstName             String
  lastName              String
  avatar                String?
  bio                   String?
  
  // Trial/Premium
  createdAt             DateTime @default(now())
  trialExpiresAt        DateTime?
  isPremium             Boolean  @default(false)
  premiumExpiresAt      DateTime?
  
  // Relations
  families              Family[]
  hostedEvents          Event[]  @relation("hosted")
  eventParticipations   EventParticipation[]
  paymentTransactions   PaymentTransaction[]
  messages              Message[]
  
  @@index([email])
}

model Family {
  id                    String   @id @default(cuid())
  name                  String
  createdAt             DateTime @default(now())
  createdById           String
  createdBy             User     @relation(fields: [createdById], references: [id], onDelete: Cascade)
  
  members               User[]
  events                Event[]
  todos                 Todo[]
  shoppingItems         ShoppingItem[]
  
  @@index([createdById])
}

model Event {
  id                    String   @id @default(cuid())
  title                 String
  description           String?
  hosterId              String
  hoster                User     @relation("hosted", fields: [hosterId], references: [id], onDelete: Cascade)
  
  familyId              String?
  family                Family?  @relation(fields: [familyId], references: [id])
  
  startDate             DateTime
  endDate               DateTime?
  location              String?
  latitude              Float?
  longitude             Float?
  price                 Decimal? @db.Decimal(10, 2)
  maxParticipants       Int?
  ageGroupMin           Int?
  ageGroupMax           Int?
  
  visibility            String   @default("public") // public, invite-only
  inviteCode            String?  @unique
  inviteCodeExpiresAt   DateTime?
  
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
  
  // Relations
  participations        EventParticipation[]
  chats                 EventChat[]
  
  @@index([hosterId])
  @@index([familyId])
  @@index([createdAt])
}

model EventParticipation {
  id                    String   @id @default(cuid())
  eventId               String
  event                 Event    @relation(fields: [eventId], references: [id], onDelete: Cascade)
  
  userId                String
  user                  User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  status                String   @default("pending") // pending, approved, declined
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
  
  @@unique([eventId, userId])
  @@index([eventId])
  @@index([userId])
}

model EventChat {
  id                    String   @id @default(cuid())
  eventId               String
  event                 Event    @relation(fields: [eventId], references: [id], onDelete: Cascade)
  
  messages              Message[]
  
  createdAt             DateTime @default(now())
  
  @@index([eventId])
}

model Message {
  id                    String   @id @default(cuid())
  content               String
  sender                User     @relation(fields: [senderId], references: [id], onDelete: Cascade)
  senderId              String
  
  eventChat             EventChat? @relation(fields: [eventChatId], references: [id], onDelete: Cascade)
  eventChatId           String?
  
  hasBeenReported       Boolean  @default(false)
  reportReason          String?
  
  createdAt             DateTime @default(now())
  
  @@index([senderId])
  @@index([eventChatId])
}

model PaymentTransaction {
  id                    String   @id @default(cuid())
  
  // Stripe Integration
  stripePaymentIntentId String?
  stripeTxnId           String?
  
  userId                String
  amount                Decimal  @db.Decimal(10, 2)
  currency              String   @default("EUR")
  status                String   // pending, completed, failed, refunded
  
  // Idempotency Key (prevent duplicate charges)
  idempotencyKey        String?  @unique
  
  // Audit Trail
  createdByType         String   // webhook, api, manual
  webhookId             String?  // Stripe webhook ID for tracking
  
  // Refund Tracking
  refundedAmount        Decimal? @db.Decimal(10, 2)
  refundedAt            DateTime?
  
  // Verification
  verifiedAt            DateTime?
  verificationDetails   String?  @db.Json
  
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
  
  @@index([userId])
  @@index([status])
  @@index([createdAt])
  @@index([stripeTxnId])
}

model Provider {
  id                    String   @id @default(cuid())
  name                  String
  category              String
  description           String?
  website               String?
  rating                Decimal? @db.Decimal(3, 2)
  ratingCount           Int      @default(0)
  
  createdAt             DateTime @default(now())
  
  @@index([category])
}

model Todo {
  id                    String   @id @default(cuid())
  familyId              String
  family                Family   @relation(fields: [familyId], references: [id], onDelete: Cascade)
  
  title                 String
  completed             Boolean  @default(false)
  priority              Int      @default(0)
  
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
  
  @@index([familyId])
}

model ShoppingItem {
  id                    String   @id @default(cuid())
  familyId              String
  family                Family   @relation(fields: [familyId], references: [id], onDelete: Cascade)
  
  item                  String
  quantity              Int      @default(1)
  completed             Boolean  @default(false)
  
  createdAt             DateTime @default(now())
  
  @@index([familyId])
}
```

---

## 🔄 Nächste Schritte nach Setup:

1. **Migrationen testen:**
   ```bash
   npx prisma migrate dev
   npx prisma studio  # UI zum Datenbank-Daten anschauen
   ```

2. **Seed-Daten importieren:**
   - Alte JSON Files in DB laden
   - Test-Daten erstellen

3. **Backend API umschreiben:**
   - Replace: `const todos = []` → `prisma.todo.findMany()`
   - Replace: `array.push()` → `prisma.todo.create()`
   - Replace: `array.filter()` → `prisma.todo.findMany({ where: {...} })`

---

## ⚠️ Wichtig:

- **Render Internal URL verwenden** (nicht External für Production)
- `.env.local` mit DATABASE_URL **nicht committen**
- Migrations **immer committen**
- Test mit `npx prisma studio` vor Production

Bereit? Sag Bescheid wenn Database erstellt ist! 🚀

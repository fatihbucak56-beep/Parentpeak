-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "passwordSalt" TEXT NOT NULL,
    "firstName" TEXT,
    "lastName" TEXT,
    "avatar" TEXT,
    "bio" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "trialExpiresAt" TIMESTAMP(3),
    "isPremium" BOOLEAN NOT NULL DEFAULT false,
    "premiumExpiresAt" TIMESTAMP(3),

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Family" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT NOT NULL,

    CONSTRAINT "Family_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FamilyRequest" (
    "id" TEXT NOT NULL,
    "fromUserId" TEXT NOT NULL,
    "toUserId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FamilyRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Event" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "hosterId" TEXT NOT NULL,
    "familyId" TEXT,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3),
    "location" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "status" TEXT NOT NULL DEFAULT 'upcoming',
    "eventType" TEXT NOT NULL DEFAULT 'generic',
    "costPerPerson" DECIMAL(10,2),
    "currency" TEXT NOT NULL DEFAULT 'EUR',
    "maxParticipants" INTEGER,
    "imageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventParticipation" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'invited',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventParticipation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventChat" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventChat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Message" (
    "id" TEXT NOT NULL,
    "chatId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "attachmentUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatReport" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "reportedById" TEXT NOT NULL,
    "chatId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "details" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolvedAt" TIMESTAMP(3),

    CONSTRAINT "ChatReport_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentTransaction" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'EUR',
    "stripePaymentIntentId" TEXT NOT NULL,
    "stripeChargId" TEXT,
    "idempotencyKey" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "refundedAmount" DECIMAL(10,2),
    "refundedAt" TIMESTAMP(3),
    "refundReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "verifiedAt" TIMESTAMP(3),
    "verifiedByType" TEXT,
    "auditDetails" JSONB,

    CONSTRAINT "PaymentTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Provider" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "contactEmail" TEXT NOT NULL,
    "contactPhone" TEXT,
    "website" TEXT,
    "imageUrl" TEXT,
    "category" TEXT NOT NULL,
    "city" TEXT,
    "country" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Provider_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Todo" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "done" BOOLEAN NOT NULL DEFAULT false,
    "familyId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dueDate" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "Todo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ShoppingItem" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "bought" BOOLEAN NOT NULL DEFAULT false,
    "familyId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "boughtAt" TIMESTAMP(3),

    CONSTRAINT "ShoppingItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_FamilyMembers" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL,

    CONSTRAINT "_FamilyMembers_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_createdAt_idx" ON "User"("createdAt");

-- CreateIndex
CREATE INDEX "Family_createdById_idx" ON "Family"("createdById");

-- CreateIndex
CREATE INDEX "FamilyRequest_fromUserId_idx" ON "FamilyRequest"("fromUserId");

-- CreateIndex
CREATE INDEX "FamilyRequest_toUserId_idx" ON "FamilyRequest"("toUserId");

-- CreateIndex
CREATE INDEX "Event_hosterId_idx" ON "Event"("hosterId");

-- CreateIndex
CREATE INDEX "Event_familyId_idx" ON "Event"("familyId");

-- CreateIndex
CREATE INDEX "Event_status_idx" ON "Event"("status");

-- CreateIndex
CREATE INDEX "Event_createdAt_idx" ON "Event"("createdAt");

-- CreateIndex
CREATE INDEX "EventParticipation_userId_idx" ON "EventParticipation"("userId");

-- CreateIndex
CREATE INDEX "EventParticipation_status_idx" ON "EventParticipation"("status");

-- CreateIndex
CREATE UNIQUE INDEX "EventParticipation_eventId_userId_key" ON "EventParticipation"("eventId", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "EventChat_eventId_key" ON "EventChat"("eventId");

-- CreateIndex
CREATE INDEX "EventChat_eventId_idx" ON "EventChat"("eventId");

-- CreateIndex
CREATE INDEX "Message_chatId_idx" ON "Message"("chatId");

-- CreateIndex
CREATE INDEX "Message_authorId_idx" ON "Message"("authorId");

-- CreateIndex
CREATE INDEX "Message_createdAt_idx" ON "Message"("createdAt");

-- CreateIndex
CREATE INDEX "ChatReport_messageId_idx" ON "ChatReport"("messageId");

-- CreateIndex
CREATE INDEX "ChatReport_reportedById_idx" ON "ChatReport"("reportedById");

-- CreateIndex
CREATE INDEX "ChatReport_status_idx" ON "ChatReport"("status");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentTransaction_stripePaymentIntentId_key" ON "PaymentTransaction"("stripePaymentIntentId");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentTransaction_idempotencyKey_key" ON "PaymentTransaction"("idempotencyKey");

-- CreateIndex
CREATE INDEX "PaymentTransaction_eventId_idx" ON "PaymentTransaction"("eventId");

-- CreateIndex
CREATE INDEX "PaymentTransaction_userId_idx" ON "PaymentTransaction"("userId");

-- CreateIndex
CREATE INDEX "PaymentTransaction_status_idx" ON "PaymentTransaction"("status");

-- CreateIndex
CREATE INDEX "PaymentTransaction_createdAt_idx" ON "PaymentTransaction"("createdAt");

-- CreateIndex
CREATE INDEX "PaymentTransaction_stripePaymentIntentId_idx" ON "PaymentTransaction"("stripePaymentIntentId");

-- CreateIndex
CREATE INDEX "Provider_category_idx" ON "Provider"("category");

-- CreateIndex
CREATE INDEX "Provider_city_idx" ON "Provider"("city");

-- CreateIndex
CREATE INDEX "Todo_familyId_idx" ON "Todo"("familyId");

-- CreateIndex
CREATE INDEX "Todo_done_idx" ON "Todo"("done");

-- CreateIndex
CREATE INDEX "ShoppingItem_familyId_idx" ON "ShoppingItem"("familyId");

-- CreateIndex
CREATE INDEX "ShoppingItem_bought_idx" ON "ShoppingItem"("bought");

-- CreateIndex
CREATE INDEX "_FamilyMembers_B_index" ON "_FamilyMembers"("B");

-- AddForeignKey
ALTER TABLE "Family" ADD CONSTRAINT "Family_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Event" ADD CONSTRAINT "Event_hosterId_fkey" FOREIGN KEY ("hosterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Event" ADD CONSTRAINT "Event_familyId_fkey" FOREIGN KEY ("familyId") REFERENCES "Family"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventParticipation" ADD CONSTRAINT "EventParticipation_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventParticipation" ADD CONSTRAINT "EventParticipation_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventChat" ADD CONSTRAINT "EventChat_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_chatId_fkey" FOREIGN KEY ("chatId") REFERENCES "EventChat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatReport" ADD CONSTRAINT "ChatReport_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatReport" ADD CONSTRAINT "ChatReport_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatReport" ADD CONSTRAINT "ChatReport_chatId_fkey" FOREIGN KEY ("chatId") REFERENCES "EventChat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentTransaction" ADD CONSTRAINT "PaymentTransaction_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentTransaction" ADD CONSTRAINT "PaymentTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Todo" ADD CONSTRAINT "Todo_familyId_fkey" FOREIGN KEY ("familyId") REFERENCES "Family"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShoppingItem" ADD CONSTRAINT "ShoppingItem_familyId_fkey" FOREIGN KEY ("familyId") REFERENCES "Family"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_FamilyMembers" ADD CONSTRAINT "_FamilyMembers_A_fkey" FOREIGN KEY ("A") REFERENCES "Family"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_FamilyMembers" ADD CONSTRAINT "_FamilyMembers_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;


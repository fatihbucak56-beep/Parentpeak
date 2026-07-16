-- AddTreasureItems
-- Create treasure items (Verschenkmarkt) schema

CREATE TABLE "TreasureItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "familyId" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "category" TEXT NOT NULL DEFAULT 'other',
    "subcategory" TEXT,
    "condition" TEXT NOT NULL DEFAULT 'good',
    "location" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "visibility" TEXT NOT NULL DEFAULT 'nearby',
    "shareRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 10,
    "isFree" BOOLEAN NOT NULL DEFAULT true,
    "price" DECIMAL(10,2),
    "currency" TEXT NOT NULL DEFAULT 'EUR',
    "photoUrl" TEXT,
    "photoUrls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "availableForPickup" BOOLEAN NOT NULL DEFAULT true,
    "pickupLocation" TEXT,
    "pickupSlots" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" TEXT NOT NULL DEFAULT 'available',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "views" INTEGER NOT NULL DEFAULT 0,
    "rating" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ratingCount" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "TreasureItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE,
    CONSTRAINT "TreasureItem_familyId_fkey" FOREIGN KEY ("familyId") REFERENCES "Family" ("id") ON DELETE SET NULL
);

CREATE TABLE "TreasureRating" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "treasureId" TEXT NOT NULL,
    "fromUserId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "TreasureRating_treasureId_fkey" FOREIGN KEY ("treasureId") REFERENCES "TreasureItem" ("id") ON DELETE CASCADE,
    CONSTRAINT "TreasureRating_fromUserId_fkey" FOREIGN KEY ("fromUserId") REFERENCES "User" ("id") ON DELETE CASCADE
);

CREATE TABLE "TreasureHandover" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "treasureId" TEXT NOT NULL,
    "requesterId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "scheduledTime" TIMESTAMP(3),
    "location" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "TreasureHandover_treasureId_fkey" FOREIGN KEY ("treasureId") REFERENCES "TreasureItem" ("id") ON DELETE CASCADE,
    CONSTRAINT "TreasureHandover_requesterId_fkey" FOREIGN KEY ("requesterId") REFERENCES "User" ("id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "TreasureRating_treasureId_fromUserId_key" ON "TreasureRating"("treasureId", "fromUserId");
CREATE INDEX "TreasureItem_userId_idx" ON "TreasureItem"("userId");
CREATE INDEX "TreasureItem_familyId_idx" ON "TreasureItem"("familyId");
CREATE INDEX "TreasureItem_status_idx" ON "TreasureItem"("status");
CREATE INDEX "TreasureItem_visibility_idx" ON "TreasureItem"("visibility");
CREATE INDEX "TreasureItem_createdAt_idx" ON "TreasureItem"("createdAt");
CREATE INDEX "TreasureItem_category_idx" ON "TreasureItem"("category");
CREATE INDEX "TreasureRating_treasureId_idx" ON "TreasureRating"("treasureId");
CREATE INDEX "TreasureRating_fromUserId_idx" ON "TreasureRating"("fromUserId");
CREATE INDEX "TreasureHandover_treasureId_idx" ON "TreasureHandover"("treasureId");
CREATE INDEX "TreasureHandover_requesterId_idx" ON "TreasureHandover"("requesterId");
CREATE INDEX "TreasureHandover_status_idx" ON "TreasureHandover"("status");

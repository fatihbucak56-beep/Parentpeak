-- Persisted interactions for GemeinsamSatt food offers (recipe-backed)

CREATE TABLE IF NOT EXISTS "FoodOfferComment" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "recipeId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "text" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "FoodOfferComment_recipeId_fkey"
    FOREIGN KEY ("recipeId") REFERENCES "SharedRecipe" ("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "FoodOfferComment_recipeId_idx"
  ON "FoodOfferComment" ("recipeId");
CREATE INDEX IF NOT EXISTS "FoodOfferComment_createdAt_idx"
  ON "FoodOfferComment" ("createdAt");

CREATE TABLE IF NOT EXISTS "FoodOfferReservation" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "recipeId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "portions" INTEGER NOT NULL DEFAULT 1,
  "completedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "FoodOfferReservation_recipeId_fkey"
    FOREIGN KEY ("recipeId") REFERENCES "SharedRecipe" ("id") ON DELETE CASCADE
);

ALTER TABLE "FoodOfferReservation"
  ADD COLUMN IF NOT EXISTS "completedAt" TIMESTAMP(3);

CREATE UNIQUE INDEX IF NOT EXISTS "FoodOfferReservation_recipeId_userId_key"
  ON "FoodOfferReservation" ("recipeId", "userId");
CREATE INDEX IF NOT EXISTS "FoodOfferReservation_recipeId_idx"
  ON "FoodOfferReservation" ("recipeId");
CREATE INDEX IF NOT EXISTS "FoodOfferReservation_userId_idx"
  ON "FoodOfferReservation" ("userId");

-- Add moderation reports for treasure listings
CREATE TABLE IF NOT EXISTS "TreasureReport" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "treasureId" TEXT NOT NULL,
  "reporterUserId" TEXT NOT NULL,
  "reason" TEXT NOT NULL,
  "note" TEXT,
  "status" TEXT NOT NULL DEFAULT 'pending',
  "moderatorId" TEXT,
  "moderatorNote" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "resolvedAt" TIMESTAMP(3),
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "TreasureReport_treasureId_fkey"
    FOREIGN KEY ("treasureId") REFERENCES "TreasureItem" ("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "TreasureReport_treasureId_idx" ON "TreasureReport"("treasureId");
CREATE INDEX IF NOT EXISTS "TreasureReport_reporterUserId_idx" ON "TreasureReport"("reporterUserId");
CREATE INDEX IF NOT EXISTS "TreasureReport_status_idx" ON "TreasureReport"("status");
CREATE INDEX IF NOT EXISTS "TreasureReport_createdAt_idx" ON "TreasureReport"("createdAt");

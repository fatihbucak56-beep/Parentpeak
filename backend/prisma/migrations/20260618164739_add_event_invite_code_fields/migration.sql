/*
  Warnings:

  - A unique constraint covering the columns `[inviteCode]` on the table `Event` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "Event" ADD COLUMN     "inviteCode" TEXT,
ADD COLUMN     "inviteCodeExpiresAt" TIMESTAMP(3),
ADD COLUMN     "shareRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 25,
ADD COLUMN     "visibility" TEXT NOT NULL DEFAULT 'publicNearby';

-- CreateIndex
CREATE UNIQUE INDEX "Event_inviteCode_key" ON "Event"("inviteCode");

-- CreateIndex
CREATE INDEX "Event_visibility_idx" ON "Event"("visibility");

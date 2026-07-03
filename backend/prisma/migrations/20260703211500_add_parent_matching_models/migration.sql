-- CreateTable
CREATE TABLE "ParentMatchingProfile" (
    "id" TEXT NOT NULL,
    "externalId" TEXT,
    "name" TEXT NOT NULL,
    "age" INTEGER NOT NULL,
    "city" TEXT NOT NULL,
    "bio" TEXT,
    "interests" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "languages" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "valuesFocus" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "childAges" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "familyForm" TEXT NOT NULL,
    "verificationLevel" TEXT NOT NULL DEFAULT 'basic',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ParentMatchingProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ParentMatchingAction" (
    "id" TEXT NOT NULL,
    "familyId" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actorUserId" TEXT,

    CONSTRAINT "ParentMatchingAction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ParentMatchingProfile_externalId_key" ON "ParentMatchingProfile"("externalId");

-- CreateIndex
CREATE INDEX "ParentMatchingProfile_city_idx" ON "ParentMatchingProfile"("city");

-- CreateIndex
CREATE INDEX "ParentMatchingProfile_isActive_idx" ON "ParentMatchingProfile"("isActive");

-- CreateIndex
CREATE INDEX "ParentMatchingProfile_createdAt_idx" ON "ParentMatchingProfile"("createdAt");

-- CreateIndex
CREATE INDEX "ParentMatchingAction_familyId_idx" ON "ParentMatchingAction"("familyId");

-- CreateIndex
CREATE INDEX "ParentMatchingAction_profileId_idx" ON "ParentMatchingAction"("profileId");

-- CreateIndex
CREATE INDEX "ParentMatchingAction_action_idx" ON "ParentMatchingAction"("action");

-- CreateIndex
CREATE INDEX "ParentMatchingAction_createdAt_idx" ON "ParentMatchingAction"("createdAt");

-- CreateIndex
CREATE INDEX "ParentMatchingAction_actorUserId_idx" ON "ParentMatchingAction"("actorUserId");

-- AddForeignKey
ALTER TABLE "ParentMatchingAction"
ADD CONSTRAINT "ParentMatchingAction_profileId_fkey"
FOREIGN KEY ("profileId") REFERENCES "ParentMatchingProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

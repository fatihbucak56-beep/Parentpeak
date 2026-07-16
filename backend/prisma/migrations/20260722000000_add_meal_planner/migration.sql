-- CreateTable MealPlan
CREATE TABLE "MealPlan" (
    "id" TEXT NOT NULL,
    "familyId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MealPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable Meal
CREATE TABLE "Meal" (
    "id" TEXT NOT NULL,
    "mealPlanId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "description" TEXT,
    "ingredients" TEXT NOT NULL DEFAULT '[]',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Meal_pkey" PRIMARY KEY ("id")
);

-- CreateIndex MealPlan
CREATE UNIQUE INDEX "MealPlan_familyId_date_key" ON "MealPlan"("familyId", "date");
CREATE INDEX "MealPlan_familyId_idx" ON "MealPlan"("familyId");
CREATE INDEX "MealPlan_date_idx" ON "MealPlan"("date");

-- CreateIndex Meal
CREATE INDEX "Meal_mealPlanId_idx" ON "Meal"("mealPlanId");
CREATE INDEX "Meal_type_idx" ON "Meal"("type");

-- AddForeignKey
ALTER TABLE "Meal" ADD CONSTRAINT "Meal_mealPlanId_fkey" FOREIGN KEY ("mealPlanId") REFERENCES "MealPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

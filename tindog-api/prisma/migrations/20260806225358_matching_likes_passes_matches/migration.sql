-- CreateTable
CREATE TABLE "likes" (
    "id" TEXT NOT NULL,
    "from_pet_id" TEXT NOT NULL,
    "to_pet_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "likes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "passes" (
    "id" TEXT NOT NULL,
    "from_pet_id" TEXT NOT NULL,
    "to_pet_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "passes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "matches" (
    "id" TEXT NOT NULL,
    "pet_a_id" TEXT NOT NULL,
    "pet_b_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "matches_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "likes_to_pet_id_idx" ON "likes"("to_pet_id");

-- CreateIndex
CREATE UNIQUE INDEX "likes_from_pet_id_to_pet_id_key" ON "likes"("from_pet_id", "to_pet_id");

-- CreateIndex
CREATE INDEX "passes_to_pet_id_idx" ON "passes"("to_pet_id");

-- CreateIndex
CREATE UNIQUE INDEX "passes_from_pet_id_to_pet_id_key" ON "passes"("from_pet_id", "to_pet_id");

-- CreateIndex
CREATE INDEX "matches_pet_b_id_idx" ON "matches"("pet_b_id");

-- CreateIndex
CREATE UNIQUE INDEX "matches_pet_a_id_pet_b_id_key" ON "matches"("pet_a_id", "pet_b_id");

-- AddForeignKey
ALTER TABLE "likes" ADD CONSTRAINT "likes_from_pet_id_fkey" FOREIGN KEY ("from_pet_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "likes" ADD CONSTRAINT "likes_to_pet_id_fkey" FOREIGN KEY ("to_pet_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "passes" ADD CONSTRAINT "passes_from_pet_id_fkey" FOREIGN KEY ("from_pet_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "passes" ADD CONSTRAINT "passes_to_pet_id_fkey" FOREIGN KEY ("to_pet_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "matches" ADD CONSTRAINT "matches_pet_a_id_fkey" FOREIGN KEY ("pet_a_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "matches" ADD CONSTRAINT "matches_pet_b_id_fkey" FOREIGN KEY ("pet_b_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

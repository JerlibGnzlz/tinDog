-- CreateEnum
CREATE TYPE "PetMediaType" AS ENUM ('photo', 'video');

-- CreateTable
CREATE TABLE "pet_media" (
    "id" TEXT NOT NULL,
    "pet_id" TEXT NOT NULL,
    "type" "PetMediaType" NOT NULL DEFAULT 'photo',
    "url" TEXT NOT NULL,
    "public_id" TEXT NOT NULL,
    "sort_order" INTEGER NOT NULL,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "duration_sec" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pet_media_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "pet_media_pet_id_idx" ON "pet_media"("pet_id");

-- AddForeignKey
ALTER TABLE "pet_media" ADD CONSTRAINT "pet_media_pet_id_fkey" FOREIGN KEY ("pet_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Migrate existing primary photos into gallery
INSERT INTO "pet_media" (
    "id",
    "pet_id",
    "type",
    "url",
    "public_id",
    "sort_order",
    "is_primary",
    "created_at",
    "updated_at"
)
SELECT
    gen_random_uuid()::text,
    "id",
    'photo',
    "photo_url",
    'legacy',
    0,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM "pets"
WHERE "photo_url" IS NOT NULL AND TRIM("photo_url") <> '';

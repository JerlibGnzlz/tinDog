-- AlterTable
ALTER TABLE "profiles" ADD COLUMN "latitude" DOUBLE PRECISION,
ADD COLUMN "longitude" DOUBLE PRECISION,
ADD COLUMN "location_updated_at" TIMESTAMP(3);
